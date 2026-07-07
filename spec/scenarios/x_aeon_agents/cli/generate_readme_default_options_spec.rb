describe XAeonAgents::Cli, '#generate_readme' do
  context 'with default options (all sections enabled)' do
    let(:default_cli_args) { [] }

    before do
      stub_doctoc
      stub_readme_generator_run
    end

    it 'generates a full README from scratch' do
      run_readme_generator
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

    it 'updates all relevant sections without modifying others' do
      run_readme_generator(
        existing_content: <<~README
          # Test Project

          Description

          ## How it works

          Old how it works content

          ## Quick start

          Old quick start content

          ## Table of contents

          - [Old TOC](#old)

          ## Specific section

          Specific content
        README
      )
      expect(readme_content).to eq <<~EO_README
        #{readme_header}

        ## Table of contents

        - [How it works](#how-it-works)
        - [Development](#development)
        - [Contributing](#contributing)
        - [License](#license)
        - [Quick start](#quick-start)
        - [Requirements](#requirements)
        - [Features](#features)
        - [Public API](#public-api)
        - [Documentation](#documentation)
        - [Specific section](#specific-section)

        ## How it works

        Generated content for how_it_works

        ## Development

        Generated content for development

        ## Contributing

        Generated content for contributing

        ## License

        Generated content for license

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

        ## Specific section

        Specific content
      EO_README
    end
  end
end
