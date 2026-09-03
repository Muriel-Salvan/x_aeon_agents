describe XAeonAgents::Agents::ReadmeGeneratorAgent do
  describe 'disabling the about section' do
    let(:default_run_kwargs) do
      {
        gen_about: false,
        gen_quick_start: true,
        gen_requirements: true,
        gen_features: true,
        gen_public_api: true,
        gen_documentation: true,
        gen_how_it_works: true,
        gen_development: true,
        gen_contributing: true,
        gen_license: true
      }
    end

    before do
      stub_doctoc
      stub_readme_generator_run
    end

    it 'generates a new README without the about header' do
      run_readme_generator(run_kwargs: default_run_kwargs, existing_content: nil)
      expect(readme_content).to eq <<~EO_README


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

        ## Quick start

        Generated content for quick_start

        ## Requirements

        Generated content for requirements

        ## Features

        Generated content for features

        ## Public API

        Generated content for public_api

        ## Documentation

        Generated content for documentation

        ## How it works

        Generated content for how_it_works

        ## Development

        Generated content for development

        ## Contributing

        Generated content for contributing

        ## License

        Generated content for license
      EO_README
    end

    it 'keeps the existing header unchanged when about is disabled' do
      run_readme_generator(
        run_kwargs: default_run_kwargs,
        existing_content: <<~EO_README
          # Custom Project

          Custom description

          ## Quick start

          Old content for quick_start

          ## Table of contents

          - [Old TOC](#old)

          ## License

          Old content for license
        EO_README
      )
      expect(readme_content).to eq <<~EO_README
        # Custom Project

        Custom description

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

        ## Quick start

        Generated content for quick_start

        ## Requirements

        Generated content for requirements

        ## Features

        Generated content for features

        ## Public API

        Generated content for public_api

        ## Documentation

        Generated content for documentation

        ## How it works

        Generated content for how_it_works

        ## Development

        Generated content for development

        ## Contributing

        Generated content for contributing

        ## License

        Generated content for license
      EO_README
    end
  end
end
