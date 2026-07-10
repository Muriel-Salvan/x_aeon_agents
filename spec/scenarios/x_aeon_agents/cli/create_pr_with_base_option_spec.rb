describe XAeonAgents::Cli, '#create_pr' do
  before do
    mock_github
    stub_git_diff_interpreter_agent
  end

  context 'with the --base option' do
    it 'pushes the branch on Github and creates a PR with the right description and branches' do
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        run_cli 'create-pr', '--base', 'develop'
        expect(exit_status).to eq 0

        # Verify GitDiffInterpreterAgent was called with the custom base ref
        expect(git_diff_interpreter_run_call).not_to be_nil
        expect(git_diff_interpreter_run_call[:kwargs]).to eq(git_ref_base: 'develop')

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

        # Verify a new PR was created with the custom base ref
        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'develop',
          'feature-branch',
          'Mocked 1-line summary of changes from base develop',
          'Mocked change intent from base git ref develop'
        )
      end
    end
  end
end
