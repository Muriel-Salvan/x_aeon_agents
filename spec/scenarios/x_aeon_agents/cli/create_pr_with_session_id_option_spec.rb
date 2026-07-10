describe XAeonAgents::Cli, '#create_pr' do
  before do
    mock_github
    stub_git_diff_interpreter_agent
  end

  context 'with the --session-id option' do
    it 'reuses cached content when the same session ID is provided and re-runs with a different one' do
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        run_cli 'create-pr', '--session-id', 'test-session'
        expect(exit_status).to eq 0

        # Verify PR was created with the first description
        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          'Mocked change intent from base git ref main'
        )

        # Override the GitDiffInterpreterAgent mock to return a different description
        # for any new instances created afterwards
        stub_git_diff_interpreter_agent(change_intent_message: 'New change intent')

        # Second call with the SAME session ID
        # The Resumable mixin caches the entire agent run, so the agent is not re-executed
        run_cli 'create-pr', '--session-id', 'test-session'
        expect(exit_status).to eq 0

        # Verify PR was still only created once (the second call was cached and did not re-run)
        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          'Mocked change intent from base git ref main'
        ).once

        # Third call with a DIFFERENT session ID
        run_cli 'create-pr', '--session-id', 'test-session-2'
        expect(exit_status).to eq 0

        # Verify PR was created with the new description (re-run with new session)
        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          'New change intent from base git ref main'
        )
      end
    end
  end
end
