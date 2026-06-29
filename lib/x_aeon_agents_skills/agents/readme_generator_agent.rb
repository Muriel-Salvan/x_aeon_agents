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
            Create an artifact named `#{about_analyzer_agent.artifact_ref(:about)}` with the high-level description of this project
              using Markdown format, compatible with Github flavor.
          EO_INSTRUCTIONS
        )

        quick_start_agent = Readme::QuickStartAgent.new(**Models.free_complex_planning)
        step_agent(
          quick_start_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's installation and usage patterns.
            Create an artifact named `#{quick_start_agent.artifact_ref(:quick_start)}` with quick installation and usage instructions
              using Markdown format, compatible with Github flavor.
          EO_INSTRUCTIONS
        )

        requirements_agent = Readme::RequirementsAgent.new(**Models.free_complex_planning)
        step_agent(
          requirements_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's dependencies, runtime environment, and prerequisites.
            Create an artifact named `#{requirements_agent.artifact_ref(:requirements)}` listing all prerequisites needed to use or run the project
              using Markdown format, compatible with Github flavor.
          EO_INSTRUCTIONS
        )

        features_agent = Readme::FeaturesAgent.new(**Models.free_complex_planning)
        step_agent(
          features_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's codebase and capabilities to identify all key features.
            Create an artifact named `#{features_agent.artifact_ref(:features)}` listing the main features of the project
              using Markdown format, compatible with Github flavor.
          EO_INSTRUCTIONS
        )

        public_api_agent = Readme::PublicApiAgent.new(**Models.free_complex_planning)
        step_agent(
          public_api_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's codebase to identify all public APIs, classes, methods, and interfaces exposed to users.
            Create an artifact named `#{public_api_agent.artifact_ref(:public_api)}` documenting the public API surface
              using Markdown format, compatible with Github flavor.
          EO_INSTRUCTIONS
        )

        documentation_agent = Readme::DocumentationAgent.new(**Models.free_complex_planning)
        step_agent(
          documentation_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Explore this project's documentation files and resources to identify all available documentation.
            Create an artifact named `#{documentation_agent.artifact_ref(:documentation)}` providing links to documentation resources
              using Markdown format, compatible with Github flavor.
          EO_INSTRUCTIONS
        )

        how_it_works_agent = Readme::HowItWorksAgent.new(**Models.free_complex_planning)
        step_agent(
          how_it_works_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's architecture, design patterns, and internal workings.
            Create an artifact named `#{how_it_works_agent.artifact_ref(:how_it_works)}` explaining the internal architecture and working principles
              using Markdown format, compatible with Github flavor.
          EO_INSTRUCTIONS
        )

        development_agent = Readme::DevelopmentAgent.new(**Models.free_complex_planning)
        step_agent(
          development_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's development setup, build system, testing framework, and development workflows.
            Create an artifact named `#{development_agent.artifact_ref(:development)}` explaining how to set up a development environment and contribute code
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
          EO_INSTRUCTIONS
        )

        license_agent = Readme::LicenseAgent.new(**Models.free_complex_planning)
        step_agent(
          license_agent,
          user_instructions: <<~EO_INSTRUCTIONS
            Analyze this project's LICENSE file to identify the license type and terms.
            Create an artifact named `#{license_agent.artifact_ref(:license)}` describing the project license
              using Markdown format, compatible with Github flavor.
          EO_INSTRUCTIONS
        )

        # Assemble README.md from all section artifacts
        step(:assemble_readme) do
          sections = {
            'About' => @artifacts[:about],
            'Quick start' => @artifacts[:quick_start],
            'Requirements' => @artifacts[:requirements],
            'Features' => @artifacts[:features],
            'Public API' => @artifacts[:public_api],
            'Documentation' => @artifacts[:documentation],
            'How it works' => @artifacts[:how_it_works],
            'Development' => @artifacts[:development],
            'Contributing' => @artifacts[:contributing],
            'License' => @artifacts[:license]
          }

          # Build Table of Contents
          toc = sections.keys.map do |title|
            anchor = title.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/-+/, '-').gsub(/\A-|-\z/, '')
            "- [#{title}](##{anchor})"
          end.join("\n")

          # Build badges
          badges = <<~EO_BADGES
            [![License](LICENSE)](LICENSE)
          EO_BADGES

          # Assemble README content
          readme_content = <<~EO_README
            # Project

            #{badges}
            <!-- TOC -->
            #{toc}
            <!-- /TOC -->

            #{sections.map { |title, content| "## #{title}\n\n#{content.strip}\n" }.join("\n")}
          EO_README

          File.write('README.md', readme_content)
        end

        puts 'README.md has been generated successfully.'

        @artifacts
      end
    end
  end
end
