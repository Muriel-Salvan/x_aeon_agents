describe XAeonAgents::Cli, '#implement_issue' do
  before do
    stub_developer_agent
  end

  context 'with Github issue comments' do
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
  end
end
