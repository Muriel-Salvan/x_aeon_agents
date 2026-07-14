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

  it 'levels up level-1 headers found in the Github issue body to level 2' do
    with_git_workspace(
      files: { 'test.txt' => "original\n" },
      remotes: { 'origin' => 'git@github.com:owner/repo.git' }
    ) do
      mock_github(
        issues: [
          {
            number: 15,
            title: 'My Issue',
            body: <<~EO_BODY,
              # Level 1 title

              Some introduction text.

              ### Level 3 subsection

              A deeper section.

              #### Level 4 detail

              Even deeper content.
            EO_BODY
            labels: [],
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

          ## Level 1 title

          Some introduction text.

          #### Level 3 subsection

          A deeper section.

          ##### Level 4 detail

          Even deeper content.

          # Associated Github issue

          - Number: 15
          - State: open
          - URL: https://github.com/owner/repo/issues/1
        EO_REQUIREMENTS
      )
    end
  end

  it 'levels down level-3 and below headers found in the Github issue body to level 2' do
    with_git_workspace(
      files: { 'test.txt' => "original\n" },
      remotes: { 'origin' => 'git@github.com:owner/repo.git' }
    ) do
      mock_github(
        issues: [
          {
            number: 15,
            title: 'My Issue',
            body: <<~EO_BODY,
              ### Level 3 subsection

              A deeper section.

              #### Level 4 detail

              Even deeper content.
            EO_BODY
            labels: [],
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

          ## Level 3 subsection

          A deeper section.

          ### Level 4 detail

          Even deeper content.

          # Associated Github issue

          - Number: 15
          - State: open
          - URL: https://github.com/owner/repo/issues/1
        EO_REQUIREMENTS
      )
    end
  end

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

  it 'includes a comments section with the issue comments when the issue has comments' do
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
            slug: 'owner/repo',
            comments: [
              {
                created_at: Time.parse('2024-01-15T10:30:00Z'),
                user_login: 'alice',
                body: 'First comment body'
              },
              {
                created_at: Time.parse('2024-01-16T14:45:00Z'),
                user_login: 'bob',
                body: 'Second comment body'
              }
            ]
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

          # Comments

          This is the conversation log that happened in this issue.
          This is provided as a reference to better understand the requirements.

          ## alice at 2024-01-15 10:30:00 UTC

          First comment body

          ## bob at 2024-01-16 14:45:00 UTC

          Second comment body

          # Associated Github issue

          - Number: 15
          - State: open
          - URL: https://github.com/owner/repo/issues/1
        EO_REQUIREMENTS
      )
    end
  end

  it 'levels comment headers properly when comments contain level-1 and level-4 and below headers' do
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
            slug: 'owner/repo',
            comments: [
              {
                created_at: Time.parse('2024-01-15T10:30:00Z'),
                user_login: 'alice',
                body: <<~EO_COMMENT
                  # Level 1 in comment

                  Intro text of the comment.

                  ## Level 2 in comment

                  More details.
                EO_COMMENT
              },
              {
                created_at: Time.parse('2024-01-16T14:45:00Z'),
                user_login: 'bob',
                body: <<~EO_COMMENT
                  #### Level 4 in comment

                  Deep content.

                  ##### Level 5 in comment

                  Even deeper content.
                EO_COMMENT
              }
            ]
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

          # Comments

          This is the conversation log that happened in this issue.
          This is provided as a reference to better understand the requirements.

          ## alice at 2024-01-15 10:30:00 UTC

          ### Level 1 in comment

          Intro text of the comment.

          #### Level 2 in comment

          More details.


          ## bob at 2024-01-16 14:45:00 UTC

          ### Level 4 in comment

          Deep content.

          #### Level 5 in comment

          Even deeper content.

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