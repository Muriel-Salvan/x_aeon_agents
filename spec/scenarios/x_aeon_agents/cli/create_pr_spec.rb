describe XAeonAgents::Cli, '#create_pr' do
  before do
    mock_github

    # Stub GitDiffInterpreterAgent.
    @git_diff_run_call = nil
    allow(XAeonAgents::Agents::GitDiffInterpreterAgent).to receive(:new).and_wrap_original do |original, *args, **kwargs|
      instance = original.call(*args, **kwargs)
      allow(instance).to receive(:run) do |**run_kwargs|
        @git_diff_run_call = { agent: instance, kwargs: run_kwargs.slice(*instance.send(:input_artifacts_contracts).keys) }
        {
          change_intent: "Mocked change intent from base git ref #{run_kwargs[:git_ref_base]}",
          one_line_summary: "Mocked 1-line summary of changes from base #{run_kwargs[:git_ref_base]}"
        }
      end
      instance
    end
  end

  # @return [Hash{Symbol => Object}, nil] The last stubbed call to [XAeonAgents::Agents::GitDiffInterpreterAgent#run], or nil if none.
  #   Contains the following properties:
  #   - agent [XAeonAgents::Agents::GitDiffInterpreterAgent] The agent that got run.
  #   - kwargs [Hash] The kwargs given to the run call (filtered by the input artifacts contracts).
  attr_reader :git_diff_run_call

  describe 'without any option' do
    it 'pushes the branch on Github and creates a PR with the right description and branches' do
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        run_cli 'create-pr'
        expect(exit_status).to eq 0

        # Verify GitDiffInterpreterAgent was called with the right base ref (default: main)
        expect(git_diff_run_call).not_to be_nil
        expect(git_diff_run_call[:kwargs]).to eq(git_ref_base: 'main')

        # Verify the branch was pushed to the remote with --force (for force-with-lease)
        expect(git_pushes).to eq [
          {
            url: 'git@github.com:owner/repo.git',
            branch: 'feature-branch',
            options: { force: true }
          }
        ]

        # Verify existing PRs were checked
        expect(github_double).to have_received(:pull_requests).with('owner/repo', state: 'open')

        # Verify a new PR was created with the right parameters
        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          'Mocked change intent from base git ref main'
        )
      end
    end
  end
  # TODO: Add 1 test case without any option, with a git workspace, on a git branch, stub calls made to GitDiffInterpreterAgent, Octokit (simulating existing PRs on Github for other branches) and Git push, and at the end of it, check all queries made to GitDiffInterpreterAgent, Octokit and Git that should have pushed on github remote and that a new PR was created.
  # TODO: Add 1 test case without any option, with a git workspace, on a git branch, stub calls made to GitDiffInterpreterAgent, Octokit (simulating an existing PR on Github) and Git push, and at the end of it, check all queries made to GitDiffInterpreterAgent, Octokit and Git that should have pushed on github remote but not created any PR.
  # TODO: Add 1 test case with the --base option, a git workspace, on a git branch, stub calls made to GitDiffInterpreterAgent, Octokit and Git push, and at the end of it, check all queries made to GitDiffInterpreterAgent, Octokit and Git that should have pushed on github remote and created a PR with the right description and branches.
  # TODO: Add 1 test case with the --requirements option, a git workspace, on a git branch, stub calls made to GitDiffInterpreterAgent, Octokit and Git push, and at the end of it, check all queries made to GitDiffInterpreterAgent, Octokit and Git that should have pushed on github remote and created a PR with the right description and branches.
  # TODO: Add 1 test case validating the use of session ID: Call the CLI with a session ID, mock GitDiffInterpreterAgent to return a different PR description, call again CLI with the same session ID, validate that the PR created has old content (it was not re-run), then run again the CLI with a different session ID, and validate that the PR was created correctly with the new description.
end
