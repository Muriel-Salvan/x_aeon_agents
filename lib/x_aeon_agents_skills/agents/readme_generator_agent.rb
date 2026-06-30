module XAeonAgentsSkills
  module Agents
    # Agent responsible for writing the README.md file of a project.
    class ReadmeGeneratorAgent < ComposableAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract
      prepend ComposableAgents::Mixins::Resumable
      prepend XAeonAgentsSkills::AgentDefaults

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @return Hash<Symbol,Object> Output artifacts content
      def run
        # Each section of the README has a dedicated agent who generates its content in an artifact.
        about_analyzer_agent = Readme::AboutAnalyzerAgent.new(**Models.free_complex_planning)
        step_agent(
          about_analyzer_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's code, features and layout.
            Devise the goal of this project, what problem it solves, and using which interface (CLI, library, web app...).
            Create an artifact named `#{about_analyzer_agent.artifact_ref(:name)}` with the name of this project.
            Create an artifact named `#{about_analyzer_agent.artifact_ref(:description)}` with a 1-line high-level description of this project
              using Markdown format, compatible with Github flavor.
            Create an artifact named `#{about_analyzer_agent.artifact_ref(:about)}` with an engaging high-level description/overview of this project
              using Markdown format, compatible with Github flavor.
            The description should be concise, in 1 small section and will serve as a the first paragraph of a README file.
            The description is intended to be for end-users and should be simple and easy to understand.
            Use emphasis, bullet points and small emojis to illustrate in a readable way the description.
          EO_INSTRUCTIONS
        )

        quick_start_agent = Readme::QuickStartAgent.new(**Models.free_complex_planning)
        step_agent(
          quick_start_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's installation and usage patterns.
            Create an artifact named `#{quick_start_agent.artifact_ref(:quick_start)}` with quick installation and usage instructions
              using Markdown format, compatible with Github flavor.
            These instructions should cover the installation and basic usage of this project, with simple examples.
          EO_INSTRUCTIONS
        )

        requirements_agent = Readme::RequirementsAgent.new(**Models.free_complex_planning)
        step_agent(
          requirements_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's dependencies, runtime environment, and prerequisites.
            Create an artifact named `#{requirements_agent.artifact_ref(:requirements)}` listing all prerequisites needed to use or run the project
              using Markdown format, compatible with Github flavor.
            Those prerequisites should be given as a short list of technical points (for example OS, languages and versions, needed libraries...).
            Only list prerequisites that are needed by the users of the project, and not provided by the installation steps.
          EO_INSTRUCTIONS
        )

        features_agent = Readme::FeaturesAgent.new(**Models.free_complex_planning)
        step_agent(
          features_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's codebase and capabilities to identify all key features.
            Create an artifact named `#{features_agent.artifact_ref(:features)}` listing the main features of the project
              using Markdown format, compatible with Github flavor.
            Those features should be summarized in a simple paragraph.
          EO_INSTRUCTIONS
        )

        public_api_agent = Readme::PublicApiAgent.new(**Models.free_complex_planning)
        step_agent(
          public_api_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's codebase to identify all public APIs, classes, methods, and interfaces exposed to users.
            Create an artifact named `#{public_api_agent.artifact_ref(:public_api)}` documenting the public API surface
              using Markdown format, compatible with Github flavor.
            The public API description should only contain public entry points of the project. Those entry points can be:
            - Executables from the `bin` directory, if any.
            - Any public method (part of yard's group `Public API` only).
            Try to document 1 simple usecase with an example for each public API you find, without getting into details.
            Provide links to more complete documentation next to the usecase example so that users can refer to more details about this specific public API.
            Links can be (by order of preference):
            - Links to the RubyDoc.info documentation for a Ruby public method (for example `https://www.rubydoc.info/gems/x-aeon_agents_skills/XAeonAgentsSkills/Agents#config-class_method`).
            - Links to the Github pages (for example `https://github.com/Muriel-Salvan/x_aeon_agents_skills/blob/main/bin/commit`).
          EO_INSTRUCTIONS
        )

        documentation_agent = Readme::DocumentationAgent.new(**Models.free_complex_planning)
        step_agent(
          documentation_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Explore this project's documentation files and resources to identify all available documentation.
            Create an artifact named `#{documentation_agent.artifact_ref(:documentation)}` providing links to documentation resources
              using Markdown format, compatible with Github flavor.
            Links can be:
            - Link to the RubyDoc.info documentation for a Ruby public method (for example `https://www.rubydoc.info/gems/x-aeon_agents_skills`).
            - Link to the main Github page (for example `https://github.com/Muriel-Salvan/x_aeon_agents_skills`).
          EO_INSTRUCTIONS
        )

        how_it_works_agent = Readme::HowItWorksAgent.new(**Models.free_complex_planning)
        step_agent(
          how_it_works_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's architecture, design patterns, and internal workings.
            Create an artifact named `#{how_it_works_agent.artifact_ref(:how_it_works)}` explaining the internal architecture and working principles
              using Markdown format, compatible with Github flavor.
            This should be summarized as a small section, not an architecture document.
          EO_INSTRUCTIONS
        )

        development_agent = Readme::DevelopmentAgent.new(**Models.free_complex_planning)
        step_agent(
          development_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's development setup, build system, testing framework, and development workflows.
            Create an artifact named `#{development_agent.artifact_ref(:development)}` explaining how to set up a development environment to code for this project
              using Markdown format, compatible with Github flavor.
          EO_INSTRUCTIONS
        )

        contributing_agent = Readme::ContributingAgent.new(**Models.free_complex_planning)
        step_agent(
          contributing_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's CONTRIBUTING guidelines, issue templates, pull request templates, and any community guidelines.
            Create an artifact named `#{contributing_agent.artifact_ref(:contributing)}` explaining how users can contribute to the project
              using Markdown format, compatible with Github flavor.
            This should be done in 1 paragraph showing how to install or setup test dependencies and how to run tests, as a whole or individually.
            Use simple examples to illustrate it.
          EO_INSTRUCTIONS
        )

        license_agent = Readme::LicenseAgent.new(**Models.free_complex_planning)
        step_agent(
          license_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's LICENSE file to identify the license type and terms.
            Create an artifact named `#{license_agent.artifact_ref(:license)}` describing the project license
              using Markdown format, compatible with Github flavor.
            If there is already a LICENSE file in this project, just provide a link to this license file.
          EO_INSTRUCTIONS
        )

        # Assemble README.md from all section artifacts
        step(:assemble_readme) do
          content = {
            'Quick start' => @artifacts[:quick_start],
            'Requirements' => @artifacts[:requirements],
            'Features' => @artifacts[:features],
            'Public API' => @artifacts[:public_api],
            'Documentation' => @artifacts[:documentation],
            'How it works' => @artifacts[:how_it_works],
            'Development' => @artifacts[:development],
            'Contributing' => @artifacts[:contributing],
            'License' => @artifacts[:license]
          }.map do |title, content|
            "## #{title}\n\n#{ComposableAgents::Utils::Markdown.align_markdown_headers(content, level: 3).strip}"
          end.join("\n\n")
          badges = []
          if Helpers.github_repo
            badges.concat [
              "[![Build](https://github.com/#{Helpers.github_repo}/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/#{Helpers.github_repo}/actions/workflows/continuous_integration.yml)",
              "[![Test Coverage](https://img.shields.io/codecov/c/gh/#{Helpers.github_repo})](https://codecov.io/gh/#{Helpers.github_repo})",
              "[![GitHub stars](https://img.shields.io/github/stars/#{Helpers.github_repo})](https://github.com/#{Helpers.github_repo}/stargazers)",
              "[![License](https://img.shields.io/github/license/#{Helpers.github_repo})](LICENSE)"
            ]
          end
          if Helpers.gem_name
            badges.concat [
              "[![Gem Version](https://badge.fury.io/rb/#{Helpers.gem_name}.svg)](https://badge.fury.io/rb/#{Helpers.gem_name})"
            ]
          end
          File.write(
            'README.md',
            <<~EO_README
              <div align="center">

              # #{@artifacts[:name]}

              #{@artifacts[:description]}

              #{badges.join("\n")}

              </div>

              #{ComposableAgents::Utils::Markdown.align_markdown_headers(@artifacts[:about], level: 2).strip}

              <!-- TOC -->
              #{generate_table_of_contents(content)}
              <!-- /TOC -->

              #{content}
            EO_README
          )
        end

        puts 'README.md has been generated successfully.'

        @artifacts
      end

      private

      # Generate a Table of Contents (String) from a Markdown document string.
      #
      # @param markdown [String] The full Markdown document content.
      # @return [String] The generated Table of Contents as a Markdown list.
      def generate_table_of_contents(markdown)
        headers = []
        # Remove fenced code blocks (```...``` sections) to avoid headers inside them
        markdown.gsub(/```.+?```/m, '').each_line do |line|
          match = line.match(/\A(#+)\s+(.+)/)
          next unless match

          headers << { level: match[1].length, title: match[2].strip }
        end
        # Build the TOC as a Markdown list with indentation matching header level
        # We anchor using the same convention as GitHub: lowercase, replace non-alnum chars with hyphens
        headers.map do |header|
          "#{
            '  ' * (header[:level] - 1)
          }- [#{
            header[:title]
          }](##{
            header[:title].downcase.gsub(/[^a-z0-9]+/, '-').gsub(/-+/, '-').gsub(/\A-|-\z/, '')
          })"
        end.join("\n")
      end
    end
  end
end
