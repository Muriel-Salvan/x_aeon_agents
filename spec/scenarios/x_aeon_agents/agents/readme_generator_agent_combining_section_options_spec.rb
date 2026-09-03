describe XAeonAgents::Agents::ReadmeGeneratorAgent do
  describe 'combining multiple section options' do
    let(:default_run_kwargs) do
      {
        gen_about: true,
        gen_quick_start: false,
        gen_requirements: false,
        gen_features: false,
        gen_public_api: false,
        gen_documentation: true,
        gen_how_it_works: false,
        gen_development: false,
        gen_contributing: false,
        gen_license: true
      }
    end

    before do
      stub_doctoc
      stub_readme_generator_run
      mock_git_remotes
    end

    it 'generates only the required sections from scratch' do
      run_readme_generator(run_kwargs: default_run_kwargs, existing_content: nil)
      expect(readme_content).to eq <<~EO_README
        #{readme_header}

        ## Table of contents

        - [Documentation](#documentation)
        - [License](#license)

        ## Documentation

        Generated content for documentation

        ## License

        Generated content for license
      EO_README
    end

    it 'updates only the required sections on an existing README' do
      run_readme_generator(
        run_kwargs: default_run_kwargs,
        existing_content: <<~EO_README
          # Old Project

          Old description

          ## Quick start

          Old quick start content

          ## Requirements

          Old requirements content

          ## Features

          Old features content

          ## Public API

          Old public API content

          ## Documentation

          Old documentation content

          ## How it works

          Old how it works content

          ## Development

          Old development content

          ## Contributing

          Old contributing content

          ## License

          Old license content

          ## Specific section

          Custom specific content
        EO_README
      )
      expect(readme_content).to eq <<~EO_README
        #{readme_header}

        ## Table of contents

        - [Quick start](#quick-start)
        - [Requirements](#requirements)
        - [Features](#features)
        - [Public API](#public-api)
        - [Documentation](#documentation)
        - [How it works](#how-it-works)
        - [Development](#development)
        - [Contributing](#contributing)
        - [License](#license)
        - [Specific section](#specific-section)

        ## Quick start

        Old quick start content

        ## Requirements

        Old requirements content

        ## Features

        Old features content

        ## Public API

        Old public API content

        ## Documentation

        Generated content for documentation

        ## How it works

        Old how it works content

        ## Development

        Old development content

        ## Contributing

        Old contributing content

        ## License

        Generated content for license

        ## Specific section

        Custom specific content
      EO_README
    end
  end
end
