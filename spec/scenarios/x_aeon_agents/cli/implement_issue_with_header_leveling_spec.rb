describe XAeonAgents::Cli, '#implement_issue' do
  before do
    stub_developer_agent
  end

  context 'with Github issue body header leveling' do
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
  end
end
