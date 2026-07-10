describe XAeonAgents::Cli, '#create_pr' do
  before do
    mock_github
    stub_git_diff_interpreter_agent
  end

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
        expect(git_diff_interpreter_run_call).not_to be_nil
        expect(git_diff_interpreter_run_call[:kwargs]).to eq(git_ref_base: 'main')

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

    it 'pushes the branch on Github and creates a PR even when other branches have existing PRs' do
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_github(
          pull_requests: [
            { ref: 'other-branch-1' },
            { ref: 'other-branch-2' }
          ]
        )
        mock_git_push
        run_cli 'create-pr'
        expect(exit_status).to eq 0

        # Verify GitDiffInterpreterAgent was called with the right base ref (default: main)
        expect(git_diff_interpreter_run_call).not_to be_nil
        expect(git_diff_interpreter_run_call[:kwargs]).to eq(git_ref_base: 'main')

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

        # Verify a new PR was created (no existing PR for this branch)
        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          'Mocked change intent from base git ref main'
        )
      end
    end

    it 'pushes the branch on Github but does not create a PR when one already exists for the current branch' do
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_github(
          pull_requests: [
            { ref: 'feature-branch', html_url: 'https://github.com/owner/repo/pull/1' }
          ]
        )
        mock_git_push
        run_cli 'create-pr'
        expect(exit_status).to eq 0

        # GitDiffInterpreterAgent is NOT called when a PR already exists for the branch
        expect(git_diff_interpreter_run_call).to be_nil

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

        # Verify NO new PR was created (already exists for this branch)
        expect(github_double).not_to have_received(:create_pull_request)
      end
    end
  end

  describe 'with the --base option' do
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

  describe 'with the --requirements option' do
    it 'pushes the branch on Github and creates a PR with the right description and branches including requirements' do
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        run_cli 'create-pr', '--requirements', 'Add a new Home button on main screen'
        expect(exit_status).to eq 0

        # Verify GitDiffInterpreterAgent was called with the right base ref (default: main)
        expect(git_diff_interpreter_run_call).not_to be_nil
        expect(git_diff_interpreter_run_call[:kwargs]).to eq(git_ref_base: 'main')

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

        # Verify a new PR was created with the requirements section in the body
        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          <<~EO_DESCRIPTION.chomp
            Mocked change intent from base git ref main

            # Initial requirements given

            Add a new Home button on main screen
          EO_DESCRIPTION
        )
      end
    end

    it 'pushes the branch on Github and creates a PR with level-1 headers from requirements aligned to level-2' do
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        run_cli 'create-pr', '--requirements', <<~REQUIREMENTS.chomp
          # Feature Request

          Add a new Home button on main screen

          ## Implementation Details

          Use a blue color scheme
        REQUIREMENTS
        expect(exit_status).to eq 0

        # Verify GitDiffInterpreterAgent was called with the right base ref (default: main)
        expect(git_diff_interpreter_run_call).not_to be_nil
        expect(git_diff_interpreter_run_call[:kwargs]).to eq(git_ref_base: 'main')

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

        # Verify a new PR was created with the requirements section and headers aligned to level-2
        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          <<~EO_DESCRIPTION.chomp
            Mocked change intent from base git ref main

            # Initial requirements given

            ## Feature Request

            Add a new Home button on main screen

            ### Implementation Details

            Use a blue color scheme
          EO_DESCRIPTION
        )
      end
    end

    it 'pushes the branch on Github and creates a PR with level-3 headers from requirements aligned to level-2' do
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        run_cli 'create-pr', '--requirements', <<~REQUIREMENTS.chomp
          ### Feature Request

          Add a new Home button on main screen

          #### Implementation Details

          Use a blue color scheme
        REQUIREMENTS
        expect(exit_status).to eq 0

        # Verify GitDiffInterpreterAgent was called with the right base ref (default: main)
        expect(git_diff_interpreter_run_call).not_to be_nil
        expect(git_diff_interpreter_run_call[:kwargs]).to eq(git_ref_base: 'main')

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

        # Verify a new PR was created with the requirements section and headers aligned to level-2
        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          <<~EO_DESCRIPTION.chomp
            Mocked change intent from base git ref main

            # Initial requirements given

            ## Feature Request

            Add a new Home button on main screen

            ### Implementation Details

            Use a blue color scheme
          EO_DESCRIPTION
        )
      end
    end
  end

  describe 'with the --session-id option' do
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
