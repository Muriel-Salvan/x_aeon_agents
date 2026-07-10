describe XAeonAgents::Cli, '#create_pr' do
  before do
    mock_github
    stub_git_diff_interpreter_agent
  end

  context 'with the --requirements option' do
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
end
