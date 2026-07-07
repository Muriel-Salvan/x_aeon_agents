describe XAeonAgents::Cli, '#generate_readme' do
  context 'when all sections are disabled' do
    let(:default_cli_args) do
      %w[
        --no-about
        --no-quick-start
        --no-requirements
        --no-features
        --no-public-api
        --no-documentation
        --no-how-it-works
        --no-development
        --no-contributing
        --no-license
      ]
    end

    before do
      stub_doctoc
    end

    it 'generates an empty README when it does not exist' do
      stub_agent_run
      run_readme_generator(existing_content: nil)
      expect(readme_content).to eq "\n\n## Table of contents\n\n\n\n\n"
    end

    it 'still re-generates the TOC of an existing README without modifying existing sections' do
      stub_agent_run
      run_readme_generator(
        existing_content: <<~README
          # Test Project

          Description

          ## Quick start

          Old content

          ## Table of contents

          - [Old TOC](#old)

          ## Specific section

          Specific content
        README
      )
      expect(readme_content).to eq <<~EO_README
        # Test Project

        Description

        ## Table of contents

        - [Quick start](#quick-start)
        - [Specific section](#specific-section)

        ## Quick start

        Old content

        ## Specific section

        Specific content
      EO_README
    end
  end
end
