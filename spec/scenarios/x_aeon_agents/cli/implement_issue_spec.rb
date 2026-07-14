describe XAeonAgents::Cli, '#implement_issue' do
  before do
    stub_developer_agent
  end

  it 'implements the issue by delegating to DeveloperAgent with the right parameters and input artifacts' do
    with_git_workspace(
      files: { 'test.txt' => "original\n" },
      remotes: { 'origin' => 'git@github.com:owner/repo.git' }
    ) do
      mock_github(
        issues: [
          {
            number: 15,
            title: 'My Issue',
            body: 'Issue body description',
            labels: [],
            state: 'open',
            slug: 'owner/repo'
          }
        ]
      )
      run_cli('implement-issue', '15')
      expect(exit_status).to eq 0

      # DeveloperAgent was called correctly
      expect(developer_agent_new_calls.size).to eq 1
      expect(developer_agent_new_calls.last[:kwargs]).to include(
        commit: true,
        pull_request: true
      )
      expect(developer_agent_run_calls.size).to eq 1
      expect(developer_agent_run_calls.last[:kwargs]).to eq(
        requirements: <<~EO_REQUIREMENTS.chomp
          # My Issue

          Issue body description

          # Associated Github issue

          - Number: 15
          - State: open
          - URL: https://github.com/owner/repo/issues/1
        EO_REQUIREMENTS
      )
    end
  end

  it 'does not invoke DeveloperAgent when the Github issue does not exist' do
    with_git_workspace(
      files: { 'test.txt' => "original\n" },
      remotes: { 'origin' => 'git@github.com:owner/repo.git' }
    ) do
      mock_github(issues: [])
      # Make Octokit raise a NotFound error when the issue is fetched, simulating a missing issue.
      allow(github_double).to receive(:issue).and_raise(Octokit::NotFound)
      allow(github_double).to receive(:issue_comments).and_raise(Octokit::NotFound)
      run_cli 'implement-issue', '999', expect_failure: true
      expect(developer_agent_new_calls).to be_empty
      expect(developer_agent_run_calls).to be_empty
    end
  end
end
