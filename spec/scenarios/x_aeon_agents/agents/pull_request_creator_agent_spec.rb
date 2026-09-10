require_relative 'shared_examples/common_behavior'

describe XAeonAgents::Agents::PullRequestCreatorAgent do
  before do
    mock_github
    stub_git_diff_interpreter_agent
  end

  it_behaves_like 'an agent with common behavior', described_class

  describe 'without any option' do
    it 'pushes the branch on Github and creates a PR with the right description and branches' do
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        described_class.new(session_id: nil).run(base_sha: 'main')

        # Verify GitDiffInterpreterAgent was called with the right base ref (default: main)
        expect(git_diff_interpreter_run_call).not_to be_nil
        expect(git_diff_interpreter_run_call[:kwargs]).to eq(git_ref_base: 'main')

        # Verify the branch was pushed to the remote with --force (for force-with-lease)
        expect(git_pushes).to eq [
          ['--force', '--', 'origin', 'feature-branch']
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
        described_class.new(session_id: nil).run(base_sha: 'main')

        # Verify GitDiffInterpreterAgent was called with the right base ref (default: main)
        expect(git_diff_interpreter_run_call).not_to be_nil
        expect(git_diff_interpreter_run_call[:kwargs]).to eq(git_ref_base: 'main')

        # Verify the branch was pushed to the remote with --force (for force-with-lease)
        expect(git_pushes).to eq [
          ['--force', '--', 'origin', 'feature-branch']
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
        described_class.new(session_id: nil).run(base_sha: 'main')

        # GitDiffInterpreterAgent is NOT called when a PR already exists for the branch
        expect(git_diff_interpreter_run_call).to be_nil

        # Verify the branch was pushed to the remote with --force (for force-with-lease)
        expect(git_pushes).to eq [
          ['--force', '--', 'origin', 'feature-branch']
        ]

        # Verify existing PRs were checked
        expect(github_double).to have_received(:pull_requests).with('owner/repo', state: 'open')

        # Verify NO new PR was created (already exists for this branch)
        expect(github_double).not_to have_received(:create_pull_request)
      end
    end
  end
end
