require 'fileutils'
require 'open3'
require 'stringio'

describe XAeonAgents::Cli, '#generate_readme' do
  before do
    stub_doctoc
  end

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

  context 'with default options (all sections enabled)' do
    let(:default_cli_args) { [] }

    before do
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

    it 'places Documentation just after Public API when Documentation does not exist before' do
      run_readme_generator(
        existing_content: <<~README
          # Old Project

          Old description

          ## Quick start

          Old quick start

          ## Public API

          Old public API

          ## How it works

          Old how it works
        README
      )
      doc_index = header_index('Documentation')
      expect(doc_index).to be > header_index('Public API')
      expect(doc_index).to be < header_index('How it works')
    end

    it 'places Documentation after Requirements if neither Public API nor Features exist before, even if Quick Start exists at the end' do
      run_readme_generator(
        '--no-features',
        '--no-public-api',
        existing_content: <<~README
          # Old Project

          Old description

          ## Requirements

          Old requirements

          ## Quick start

          Old quick start
        README
      )
      doc_index = header_index('Documentation')
      expect(doc_index).to be > header_index('Requirements')
      expect(doc_index).to be < header_index('Quick start')
    end

    it 'keeps Documentation before Features when it was already there' do
      run_readme_generator(
        existing_content: <<~README
          # Old Project

          Old description

          ## Documentation

          Old documentation

          ## Features

          Old features
        README
      )
      expect(header_index('Documentation')).to be < header_index('Features')
    end
  end

  context 'when disabling individual sections' do
    before do
      stub_readme_generator_run
    end

    context 'when disabling about section' do
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

    XAeonAgentsTest::Helpers::GenerateReadme.readme_sections.each_key do |section_name|
      context "when disabling #{section_name} section" do
        let(:default_cli_args) do
          %w[--about] + readme_sections.keys.map { |name| name == section_name ? "--no-#{name}" : "--#{name}" }
        end

        it "does not include the #{section_name} section when disabled from a new README" do
          run_readme_generator(existing_content: nil)
          readme_sections.each do |name, title|
            if name == section_name
              expect_no_section(title)
            else
              expect_section(title, "Generated content for #{name}")
            end
          end
        end

        it "does not modify the #{section_name} section when disabled" do
          run_readme_generator(
            existing_content: <<~EO_README
              # Test project

              ## Table of contents

              - [Old](#old)

              #{readme_sections.map { |name, title| "## #{title}\n\nOld content for #{name}" }.join("\n\n")}
            EO_README
          )
          expect(readme_content).to include('Test Project')
          expect(readme_content).to include('A test project')
          readme_sections.each do |name, title|
            if name == section_name
              expect_section(title, "Old content for #{name}")
            else
              expect_section(title, "Generated content for #{name}")
            end
          end
        end
      end
    end
  end

  context 'when combining multiple section options' do
    let(:default_cli_args) do
      %w[
        --about
        --no-quick-start
        --no-requirements
        --no-features
        --no-public-api
        --documentation
        --no-how-it-works
        --no-development
        --no-contributing
        --license
      ]
    end

    before do
      stub_readme_generator_run
    end

    it 'generates only the required sections from scratch' do
      run_readme_generator(existing_content: nil)
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

  it 'uses README.md in the current directory when --readme-file-path is not specified' do
    stub_readme_generator_run
    default_readme = File.expand_path('README.md')
    # Mock reading the existing README.md so we do not touch the real file.
    # Other File.read calls (e.g. the temporary TOC file read by the mocked doctoc)
    # still behave normally.
    allow(File).to receive(:read).and_wrap_original do |original_read, path, *args, **kwargs|
      if path == default_readme
        <<~EO_README
          # Old Project

          Old description

          #{readme_sections.map { |_name, title| "## #{title}\n\nOld content" }.join("\n\n")}
        EO_README
      else
        original_read.call(path, *args, **kwargs)
      end
    end
    allow(File).to receive(:exist?).and_wrap_original do |original_exist, path, *args, **kwargs|
      path == default_readme || original_exist.call(path, *args, **kwargs)
    end
    # Capture the content passed to File.write without modifying the real README.md.
    # Other File.write calls (e.g. the temporary TOC file) are still performed so the
    # mocked doctoc command can read from them.
    new_readme_content = nil
    allow(File).to receive(:write).and_wrap_original do |original_write, path, content, *args, **kwargs|
      if path == default_readme
        new_readme_content = content
      else
        original_write.call(path, content, *args, **kwargs)
      end
    end
    run_cli('generate-readme')
    expect(new_readme_content).to eq <<~EO_README
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

  it 'does not regenerate the README when using --session-id on subsequent calls' do
    stub_readme_generator_run
    run_readme_generator('--session-id', 'test-session-123')
    first_content = readme_content
    expect(first_content).to include('Generated content for quick_start')
    modified_content = first_content.gsub('Generated content for quick_start', 'Manually modified quick start')
    File.write(readme_path, modified_content)
    run_readme_generator('--session-id', 'test-session-123')
    expect(readme_content).to include('Manually modified quick start')
    run_readme_generator('--session-id', 'test-session-456')
    last_content = readme_content
    expect(last_content).not_to include('Manually modified quick start')
    expect(last_content).to include('Generated content for quick_start')
  end
end
