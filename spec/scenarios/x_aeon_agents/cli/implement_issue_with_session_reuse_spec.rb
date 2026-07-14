describe XAeonAgents::Cli, '#implement_issue' do
  before do
    stub_developer_agent
  end

  context 'with session reuse' do
    it 'reuses the session to skip development but re-fetches the issue, and re-runs with a new description when changed' do
      slug = 'owner/repo'
      issue_number = 15

      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'origin' => "git@github.com:#{slug}.git" }
      ) do
        # First run with session-id 'session-1'
        mock_github(
          issues: [
            {
              number: issue_number,
              title: 'My Issue',
              body: 'First issue description',
              slug: slug
            }
          ]
        )
        run_cli 'implement-issue', issue_number.to_s, '--session-id', 'session-1'
        expect(exit_status).to eq 0

        expect(github_double).to have_received(:issue).with(slug, issue_number).once
        expect(github_double).to have_received(:issue_comments).with(slug, issue_number).once
        expect(developer_agent_run_calls.size).to eq 1
        expect(developer_agent_run_calls.last[:kwargs]).to eq(
          requirements: <<~EO_REQUIREMENTS.chomp
            # My Issue

            First issue description

            # Associated Github issue

            - Number: 15
            - State: open
            - URL: https://github.com/owner/repo/issues/1
          EO_REQUIREMENTS
        )

        # Second run with the same session-id: Octokit is called again to fetch the issue,
        # but DeveloperAgent is NOT invoked again (session reused).
        run_cli 'implement-issue', issue_number.to_s, '--session-id', 'session-1'
        expect(exit_status).to eq 0

        expect(github_double).to have_received(:issue).with(slug, issue_number).twice
        expect(github_double).to have_received(:issue_comments).with(slug, issue_number).twice
        expect(developer_agent_run_calls.size).to eq 1

        # Change the Octokit stub to return a different issue description.
        mock_github(
          issues: [
            {
              number: issue_number,
              title: 'My Issue',
              body: 'Updated issue description',
              slug: slug
            }
          ]
        )

        # Third run with the same session-id: the new description is detected (issue re-fetched),
        # DeveloperAgent runs again with the new description.
        run_cli 'implement-issue', issue_number.to_s, '--session-id', 'session-1'
        expect(exit_status).to eq 0

        expect(github_double).to have_received(:issue).with(slug, issue_number).exactly(3).times
        expect(github_double).to have_received(:issue_comments).with(slug, issue_number).exactly(3).times
        expect(developer_agent_run_calls.size).to eq 2
        expect(developer_agent_run_calls.last[:kwargs]).to eq(
          requirements: <<~EO_REQUIREMENTS.chomp
            # My Issue

            Updated issue description

            # Associated Github issue

            - Number: 15
            - State: open
            - URL: https://github.com/owner/repo/issues/1
          EO_REQUIREMENTS
        )
      end
    end
  end
end
