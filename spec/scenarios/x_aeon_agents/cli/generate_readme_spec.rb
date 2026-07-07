require 'fileutils'
require 'open3'
require 'stringio'

SECTIONS = {
  quick_start: 'Quick start',
  requirements: 'Requirements',
  features: 'Features',
  public_api: 'Public API',
  documentation: 'Documentation',
  how_it_works: 'How it works',
  development: 'Development',
  contributing: 'Contributing',
  license: 'License'
}.freeze

MOCKED_ARTIFACTS = {
  XAeonAgents::Agents::Readme::AboutAnalyzerAgent => :about,
  XAeonAgents::Agents::Readme::QuickStartAgent => :quick_start,
  XAeonAgents::Agents::Readme::RequirementsAgent => :requirements,
  XAeonAgents::Agents::Readme::FeaturesAgent => :features,
  XAeonAgents::Agents::Readme::PublicApiAgent => :public_api,
  XAeonAgents::Agents::Readme::DocumentationAgent => :documentation,
  XAeonAgents::Agents::Readme::HowItWorksAgent => :how_it_works,
  XAeonAgents::Agents::Readme::DevelopmentAgent => :development,
  XAeonAgents::Agents::Readme::ContributingAgent => :contributing,
  XAeonAgents::Agents::Readme::LicenseAgent => :license
}.freeze

# Stub the ABOUT_HEADER content for reference in expected outputs
FULL_HEADER = <<~EO_HEADER.chomp
  <div align="center">

  # Test Project

  A test project

  [![Build](https://github.com/Muriel-Salvan/x_aeon_agents/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/Muriel-Salvan/x_aeon_agents/actions/workflows/continuous_integration.yml)
  [![Test Coverage](https://img.shields.io/codecov/c/gh/Muriel-Salvan/x_aeon_agents)](https://codecov.io/gh/Muriel-Salvan/x_aeon_agents)
  [![GitHub stars](https://img.shields.io/github/stars/Muriel-Salvan/x_aeon_agents)](https://github.com/Muriel-Salvan/x_aeon_agents/stargazers)
  [![License](https://img.shields.io/github/license/Muriel-Salvan/x_aeon_agents)](LICENSE)
  [![Gem Version](https://img.shields.io/gem/v/x_aeon_agents)](https://rubygems.org/gems/x_aeon_agents)
  [![Gem Total Downloads](https://img.shields.io/gem/dt/x_aeon_agents)](https://rubygems.org/gems/x_aeon_agents)

  </div>

  Generated content for about
EO_HEADER

describe XAeonAgents::Cli, '#generate_readme' do
  before do
    stub_doctoc
  end

  # @return [String] The suffix for test README files
  let(:readme_suffix) { 'default' }

  # @return [String] The generated readme content
  let(:readme_content) do
    File.read(readme_path)
  end

  # @return [String] Path to the test README file
  let(:readme_path) do
    File.join(temp_dir('readme'), "readme_#{readme_suffix}.md")
  end

  # Run the README generator and capture its output.
  #
  # @param cli_args [Array<String>] CLI arguments to pass to the generator
  # @param existing_content [String, nil] Optional content to write to the file before generation
  def run_readme_generator(*cli_args, existing_content: nil)
    # Write existing content if provided
    File.write(readme_path, existing_content) if existing_content
    run_cli 'generate-readme', '--readme-file-path', readme_path, *cli_args
  end

  # Stub the README generator agent run with mocked responses
  #
  # Stubs all README section agents to return test data for each section
  def stub_readme_generator_run
    stub_agent_run(
      stub_handler: lambda { |agent, **_kwargs|
        agent.track_message(message: 'mocked AI response', author: 'assistant')
        output_artifacts = {}
        output_artifacts.merge!(name: 'Test Project', description: 'A test project') if agent.is_a?(XAeonAgents::Agents::Readme::AboutAnalyzerAgent)
        output_artifacts.merge!(MOCKED_ARTIFACTS[agent.class] => "Generated content for #{MOCKED_ARTIFACTS[agent.class]}") if MOCKED_ARTIFACTS.key?(agent.class)
        output_artifacts
      }
    )
  end

  # Stub the doctoc command to avoid running it during tests
  #
  # Mocks the Open3.popen3 call for doctoc to return a successful exit status and basic TOC
  def stub_doctoc
    allow(Open3).to receive(:popen3).and_call_original
    allow(Open3).to receive(:popen3).with(/^npx doctoc --github --notitle --stdout .+$/) do |cmd, &block|
      source_file = cmd.match(/^npx doctoc --github --notitle --stdout (.+)$/)[1]
      # Get all header names of type `## {header_name}\n` from the source file.
      stdout_io = StringIO.new(
        File.read(source_file).scan(/^## (.+)$/).flatten.map do |header_name|
          "- [#{header_name}](##{header_name.gsub(/[^\w]/, '-').downcase})"
        end.join("\n")
      )
      stderr_io = StringIO.new('')
      stdin_io = StringIO.new
      wait_thr = instance_double(Process::Waiter, value: instance_double(Process::Status, exitstatus: 0))
      block.call(stdin_io, stdout_io, stderr_io, wait_thr)
    end
  end

  # Assert that a README file contains a specific section with expected content
  #
  # @param section_title [String] Title of the section to verify (without ## prefix)
  # @param expected_content [String] Content that should be present in the section
  def expect_section(section_title, expected_content)
    expect(readme_content).to include("## #{section_title}")
    expect(readme_content).to include(expected_content)
  end

  # Assert that a README file does not contain a specific section
  #
  # @param section_title [String] Title of the section that should not be present (without ## prefix)
  def expect_no_section(section_title)
    expect(readme_content).not_to include("## #{section_title}")
  end

  # Get the 0-based line index of a section header (of the form `## {title}`) in the generated README.
  #
  # @param header_title [String] Title of the section header to locate, without the leading `## ` prefix
  #   (e.g. 'Documentation', 'Public API').
  # @return [Integer, nil] The index of the line holding the header (matched on a stripped `## {header_title}`
  #   line), or nil if no such header is present in the README.
  def header_index(header_title)
    readme_content.lines.index { |line| line.strip == "## #{header_title}" }
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
        #{FULL_HEADER}

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
        #{FULL_HEADER}

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

    SECTIONS.each_key do |section_name|
      context "when disabling #{section_name} section" do
        let(:default_cli_args) do
          %w[--about] + SECTIONS.keys.map { |name| name == section_name ? "--no-#{name}" : "--#{name}" }
        end

        it "does not include the #{section_name} section when disabled from a new README" do
          run_readme_generator(existing_content: nil)
          SECTIONS.each do |name, title|
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

              #{SECTIONS.map { |name, title| "## #{title}\n\nOld content for #{name}" }.join("\n\n")}
            EO_README
          )
          expect(readme_content).to include('Test Project')
          expect(readme_content).to include('A test project')
          SECTIONS.each do |name, title|
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
        #{FULL_HEADER}

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
        #{FULL_HEADER}

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

          #{SECTIONS.map { |_name, title| "## #{title}\n\nOld content" }.join("\n\n")}
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
      #{FULL_HEADER}

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
    first_content = File.read(readme_path)
    expect(first_content).to include('Generated content for quick_start')
    modified_content = first_content.gsub('Generated content for quick_start', 'Manually modified quick start')
    File.write(readme_path, modified_content)
    run_readme_generator('--session-id', 'test-session-123')
    expect(File.read(readme_path)).to include('Manually modified quick start')
    run_readme_generator('--session-id', 'test-session-456')
    last_content = File.read(readme_path)
    expect(last_content).not_to include('Manually modified quick start')
    expect(last_content).to include('Generated content for quick_start')
  end
end
