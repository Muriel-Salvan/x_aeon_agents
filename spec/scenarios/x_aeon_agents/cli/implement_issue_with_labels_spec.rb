describe XAeonAgents::Cli, '#implement_issue' do
  before do
    stub_developer_agent
  end

  context 'with Github issue labels' do
    it 'includes the issue labels in the associated Github issue section when the issue has labels' do
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
              labels: %w[bug enhancement],
              state: 'open',
              slug: 'owner/repo'
            }
          ]
        )
        run_cli('implement-issue', '15')
        expect(exit_status).to eq 0

        expect(developer_agent_run_calls.size).to eq 1
        expect(developer_agent_run_calls.last[:kwargs]).to eq(
          requirements: <<~EO_REQUIREMENTS.chomp
            # My Issue

            Issue body description

            # Associated Github issue

            - Number: 15
            - Labels: bug, enhancement
            - State: open
            - URL: https://github.com/owner/repo/issues/1
          EO_REQUIREMENTS
        )
      end
    end
  end
end
