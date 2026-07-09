require 'stringio'

module XAeonAgentsTest
  module Helpers
    # Helpers used in tests of the README generation
    module GenerateReadme
      # Get the list of sections that are handled by our README generator
      #
      # @return [Hash{Symbol => String}] The set of section's title, per section name.
      def self.readme_sections
        {
          quick_start: 'Quick start',
          requirements: 'Requirements',
          features: 'Features',
          public_api: 'Public API',
          documentation: 'Documentation',
          how_it_works: 'How it works',
          development: 'Development',
          contributing: 'Contributing',
          license: 'License'
        }
      end

      # Get the list of sections that are handled by our README generator
      #
      # @return [Hash{Symbol => String}] The set of section's title, per section name.
      def readme_sections
        GenerateReadme.readme_sections
      end

      # Return the test README file content
      #
      # @return [String] The test README content
      def readme_content
        File.read(readme_path)
      end

      # Get a memoized path to a test README file
      #
      # @return [String] Memoized path to the test README file
      def readme_path
        @readme_path ||= File.join(temp_dir('readme'), 'readme.md')
      end

      # Get the README header as it is generated during tests
      #
      # @return [String] The README header
      def readme_header
        <<~EO_HEADER.chomp
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
      }

      # Stub the README generator agent run with mocked responses
      #
      # Stubs all README section agents to return test data for each section
      def stub_readme_generator_run
        stub_agent_run(
          stub_handler: lambda { |agent, **_kwargs|
            agent.track_message(message: 'mocked AI response', author: 'assistant')
            output_artifacts = {}
            output_artifacts.merge!(name: 'Test Project', description: 'A test project') if agent.is_a?(XAeonAgents::Agents::Readme::AboutAnalyzerAgent)
            if MOCKED_ARTIFACTS.key?(agent.class)
              output_artifacts.merge!(MOCKED_ARTIFACTS[agent.class] => "Generated content for #{MOCKED_ARTIFACTS[agent.class]}")
            end
            output_artifacts
          }
        )
      end

      # Mocks the doctoc command to return a successful exit status and basic TOC
      def stub_doctoc
        stub_command(
          /^npx doctoc --github --notitle --stdout .+$/,
          stdout: proc do |command|
            # Get all header names of type `## {header_name}\n` from the source file.
            File.read(command.match(/^npx doctoc --github --notitle --stdout (.+)$/)[1]).scan(/^## (.+)$/).flatten.map do |header_name|
              "- [#{header_name}](##{header_name.gsub(/[^\w]/, '-').downcase})"
            end.join("\n")
          end
        )
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
    end
  end
end
