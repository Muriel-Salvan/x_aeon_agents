describe XAeonAgents::Agents::ReadmeGeneratorAgent do
  describe 'all sections disabled' do
    let(:default_run_kwargs) do
      {
        gen_about: false,
        gen_quick_start: false,
        gen_requirements: false,
        gen_features: false,
        gen_public_api: false,
        gen_documentation: false,
        gen_how_it_works: false,
        gen_development: false,
        gen_contributing: false,
        gen_license: false
      }
    end

    before do
      stub_doctoc
    end

    it 'generates an empty README when it does not exist' do
      stub_agent_run
      run_readme_generator(run_kwargs: default_run_kwargs, existing_content: nil)
      expect(readme_content).to eq "

## Table of contents




"
    end

    it 'still re-generates the TOC of an existing README without modifying existing sections' do
      stub_agent_run
      run_readme_generator(
        run_kwargs: default_run_kwargs,
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
