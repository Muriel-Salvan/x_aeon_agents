describe XAeonAgents::Cli, '#generate_readme' do
  context 'when disabling the about section' do
    let(:default_cli_args) do
      %w[
        --no-about
        --quick-start
        --requirements
        --features
        --public-api
        --documentation
        --how-it-works
        --development
        --contributing
        --license
      ]
    end

    before do
      stub_doctoc
      stub_readme_generator_run
    end

    it 'generates a new README without the about header' do
      run_readme_generator(existing_content: nil)
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
