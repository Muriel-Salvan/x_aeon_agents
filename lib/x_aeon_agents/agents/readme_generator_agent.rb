require 'commonmarker'

module XAeonAgents
  module Agents
    # Agent responsible for writing the README.md file of a project.
    class ReadmeGeneratorAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          gen_about: 'Generate the about/header section (name, description, badges, TOC)',
          gen_quick_start: 'Generate the "Quick start" section',
          gen_requirements: 'Generate the "Requirements" section',
          gen_features: 'Generate the "Features" section',
          gen_public_api: 'Generate the "Public API" section',
          gen_documentation: 'Generate the "Documentation" section',
          gen_how_it_works: 'Generate the "How it works" section',
          gen_development: 'Generate the "Development" section',
          gen_contributing: 'Generate the "Contributing" section',
          gen_license: 'Generate the "License" section'
        }
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param gen_about [Boolean] Generate the about/header section (name, description, badges, TOC).
      #   Setting this to false will keep the existing header untouched in the README while allowing
      #   other sections to be updated.
      # @param gen_quick_start [Boolean] Generate the "Quick start" section
      # @param gen_requirements [Boolean] Generate the "Requirements" section
      # @param gen_features [Boolean] Generate the "Features" section
      # @param gen_public_api [Boolean] Generate the "Public API" section
      # @param gen_documentation [Boolean] Generate the "Documentation" section
      # @param gen_how_it_works [Boolean] Generate the "How it works" section
      # @param gen_development [Boolean] Generate the "Development" section
      # @param gen_contributing [Boolean] Generate the "Contributing" section
      # @param gen_license [Boolean] Generate the "License" section
      # @return Hash<Symbol,Object> Output artifacts content
      def run(
        gen_about: true,
        gen_quick_start: true,
        gen_requirements: true,
        gen_features: true,
        gen_public_api: true,
        gen_documentation: true,
        gen_how_it_works: true,
        gen_development: true,
        gen_contributing: true,
        gen_license: true
      )
        # Each section of the README has a dedicated agent who generates its content in an artifact.
        if gen_about
          about_analyzer_agent = new_agent(Readme::AboutAnalyzerAgent, **Models.free_complex_planning)
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
        end

        if gen_quick_start
          quick_start_agent = new_agent(Readme::QuickStartAgent, **Models.free_complex_planning)
          step_agent(
            quick_start_agent,
            user_instructions: <<~EO_INSTRUCTIONS
              Analyze this project's installation and usage patterns.
              Create an artifact named `#{quick_start_agent.artifact_ref(:quick_start)}` with quick installation and usage instructions
                using Markdown format, compatible with Github flavor.
              These instructions should cover the installation and basic usage of this project, with simple examples.
            EO_INSTRUCTIONS
          )
        end

        if gen_requirements
          requirements_agent = new_agent(Readme::RequirementsAgent, **Models.free_complex_planning)
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
        end

        if gen_features
          features_agent = new_agent(Readme::FeaturesAgent, **Models.free_complex_planning)
          step_agent(
            features_agent,
            user_instructions: <<~EO_INSTRUCTIONS
              Analyze this project's codebase and capabilities to identify all key features.
              Create an artifact named `#{features_agent.artifact_ref(:features)}` listing the main features of the project
                using Markdown format, compatible with Github flavor.
              Those features should be summarized in a simple paragraph.
            EO_INSTRUCTIONS
          )
        end

        if gen_public_api
          public_api_agent = new_agent(Readme::PublicApiAgent, **Models.free_complex_planning)
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
              - Links to the RubyDoc.info documentation for a Ruby public method (for example `https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Agents#config-class_method`).
              - Links to the Github pages (for example `https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/bin/commit`).
            EO_INSTRUCTIONS
          )
        end

        if gen_documentation
          documentation_agent = new_agent(Readme::DocumentationAgent, **Models.free_complex_planning)
          step_agent(
            documentation_agent,
            user_instructions: <<~EO_INSTRUCTIONS
              Explore this project's documentation files and resources to identify all available documentation.
              Create an artifact named `#{documentation_agent.artifact_ref(:documentation)}` providing links to documentation resources
                using Markdown format, compatible with Github flavor.
              Links can be:
              - Link to the RubyDoc.info documentation for a Ruby public method (for example `https://www.rubydoc.info/gems/x_aeon_agents`).
              - Link to the main Github page (for example `https://github.com/Muriel-Salvan/x_aeon_agents`).
            EO_INSTRUCTIONS
          )
        end

        if gen_how_it_works
          how_it_works_agent = new_agent(Readme::HowItWorksAgent, **Models.free_complex_planning)
          step_agent(
            how_it_works_agent,
            user_instructions: <<~EO_INSTRUCTIONS
              Analyze this project's architecture, design patterns, and internal workings.
              Create an artifact named `#{how_it_works_agent.artifact_ref(:how_it_works)}` explaining the internal architecture and working principles
                using Markdown format, compatible with Github flavor.
              This should be summarized as a small section, not an architecture document.
            EO_INSTRUCTIONS
          )
        end

        if gen_development
          development_agent = new_agent(Readme::DevelopmentAgent, **Models.free_complex_planning)
          step_agent(
            development_agent,
            user_instructions: <<~EO_INSTRUCTIONS
              Analyze this project's development setup, build system, testing framework, and development workflows.
              Create an artifact named `#{development_agent.artifact_ref(:development)}` explaining how to set up a development environment to code for this project
                using Markdown format, compatible with Github flavor.
            EO_INSTRUCTIONS
          )
        end

        if gen_contributing
          contributing_agent = new_agent(Readme::ContributingAgent, **Models.free_complex_planning)
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
        end

        if gen_license
          license_agent = new_agent(Readme::LicenseAgent, **Models.free_complex_planning)
          step_agent(
            license_agent,
            user_instructions: <<~EO_INSTRUCTIONS
              Analyze this project's LICENSE file to identify the license type and terms.
              Create an artifact named `#{license_agent.artifact_ref(:license)}` describing the project license
                using Markdown format, compatible with Github flavor.
              If there is already a LICENSE file in this project, just provide a link to this license file.
            EO_INSTRUCTIONS
          )
        end

        # Assemble README.md from all section artifacts
        step(:assemble_readme) do
          sections = File.exist?('README.md') ? parse_sections(File.read('README.md')) : []

          # We expect the first 2 sections to be of level 0 or 1, and they both correspond to the about top section.
          # Merge them if that's the case.
          if sections.size >= 2 && sections[0][:level].zero? && sections[1][:level] == 1
            sections = [
              {
                level: 0,
                title: nil,
                body: "#{sections[0][:body]}\n\n#{sections[1][:body]}"
              }
            ] + sections[2..]
          end

          # Remove the eventual Table of contents section as we will always regenerate it.
          sections.delete_if { |section| section[:title] == 'Table of contents' }

          # Replace or insert sections in the order they are expected

          if gen_about
            header_content = <<~EO_HEADER.strip
              <div align="center">

              # #{@artifacts[:name]}

              #{@artifacts[:description]}

              #{build_badges.join("\n")}

              </div>

              #{ComposableAgents::Utils::Markdown.align_markdown_headers(@artifacts[:about], level: 3).strip}
            EO_HEADER
            if sections.size >= 1 && sections.first[:level].zero?
              sections[0][:body] = header_content
            else
              sections.unshift(
                level: 0,
                title: nil,
                body: header_content
              )
            end
          end

          ordered_sections = [
            ['Quick start', :quick_start],
            ['Requirements', :requirements],
            ['Features', :features],
            ['Public API', :public_api],
            ['Documentation', :documentation],
            ['How it works', :how_it_works],
            ['Development', :development],
            ['Contributing', :contributing],
            ['License', :license]
          ]
          ordered_sections.each.with_index do |(section_title, art_name), idx_section|
            next unless @artifacts[art_name]

            content = "## #{section_title}\n\n#{ComposableAgents::Utils::Markdown.align_markdown_headers(strip_grouping_header(@artifacts[art_name]), level: 3).strip}"
            # Find the section of this title if any
            existing_idx = sections.index { |section| section[:title] == section_title }
            if existing_idx
              sections[existing_idx][:body] = content
            else
              # Look for the first previous section.
              # The we insert our section just after.
              found_previous_section_index = nil
              previous_section_index = idx_section - 1
              while found_previous_section_index.nil?
                if previous_section_index == -1
                  # We didn't find any previous section.
                  # Just insert after the header then.
                  found_previous_section_index = 0
                else
                  previous_section_title = ordered_sections[previous_section_index][0]
                  found_previous_section_index = sections.index { |section| section[:title] == previous_section_title }
                end
                previous_section_index -= 1
              end
              # Insert just after found_previous_section_index
              sections.insert(
                found_previous_section_index + 1,
                {
                  level: 2,
                  title: section_title,
                  body: content
                }
              )
            end
          end

          sections_body = sections[1..].map { |section| section[:body] }.join("\n\n").strip
          File.write(
            'README.md',
            <<~EO_README
              #{sections.first[:body].strip}

              ## Table of contents

              #{generate_table_of_contents(sections_body).strip}

              #{sections_body}
            EO_README
          )
        end

        puts 'README.md has been generated successfully.'

        @artifacts
      end

      private

      # Build the badges array for the README header.
      #
      # @return [Array<String>]
      def build_badges
        badges = []
        if Helpers.github_repo
          badges.push(
            "[![Build](https://github.com/#{Helpers.github_repo}/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/#{Helpers.github_repo}/actions/workflows/continuous_integration.yml)",
            "[![Test Coverage](https://img.shields.io/codecov/c/gh/#{Helpers.github_repo})](https://codecov.io/gh/#{Helpers.github_repo})",
            "[![GitHub stars](https://img.shields.io/github/stars/#{Helpers.github_repo})](https://github.com/#{Helpers.github_repo}/stargazers)",
            "[![License](https://img.shields.io/github/license/#{Helpers.github_repo})](LICENSE)"
          )
        end
        if Helpers.gem_name
          badges.push(
            "[![Gem Version](https://img.shields.io/gem/v/#{Helpers.gem_name})](https://rubygems.org/gems/#{Helpers.gem_name})",
            "[![Gem Total Downloads](https://img.shields.io/gem/dt/#{Helpers.gem_name})](https://rubygems.org/gems/#{Helpers.gem_name})"
          )
        end
        badges
      end

      # Parse an existing README content into an array of section hashes using CommonMarker.
      #
      # Each section hash has:
      #   :level - heading level (1 or 2, or 0 for the leading header block before any heading)
      #   :title - heading text (nil for the leading header block)
      #   :body  - raw markdown body (includes the heading line itself for level>=1 sections)
      #
      # @param readme_content [String] Full README markdown content
      # @return [Array<Hash{Symbol => Object}>]
      def parse_sections(readme_content)
        sections = []
        # Track (1-indexed) source line of the last heading we encountered
        last_heading_line = nil
        lines = readme_content.lines.map(&:chomp)
        Commonmarker.parse(readme_content, options: { sourcepos_chars: true }).walk do |node|
          next unless node.type == :heading && node.header_level <= 2

          heading_line = node.source_position[:start_line] # 1-indexed
          if last_heading_line
            # Body is lines from last heading up to (not including) this heading
            sections.last[:body] = lines[(last_heading_line - 1)...(heading_line - 1)].join("\n").strip
          elsif heading_line > 1
            # Capture the leading header (lines before the first heading)
            sections << {
              level: 0,
              title: nil,
              body: lines[0...(heading_line - 1)].join("\n").strip
            }
          end
          text_node = node.each.find { |c| c.type == :text }
          sections << {
            level: node.header_level,
            title: text_node ? text_node.string_content : '',
            body: nil # placeholder, will be filled by the next heading
          }
          last_heading_line = heading_line
        end
        # Capture the body of the last section (from its heading to end of file)
        if last_heading_line
          sections.last[:body] = lines[(last_heading_line - 1)..].join("\n").strip
        else
          # No headings at all — entire content is one header block
          sections << {
            level: 0,
            title: nil,
            body: readme_content.strip
          }
        end
        sections
      end

      # If the markdown content has exactly 1 heading at the smallest level present,
      # remove it. This strips the "grouping" header that AI-generated sections
      # sometimes produce (e.g. a single `#` or `##` wrapping the rest of the content).
      #
      # @param markdown [String] The markdown content to process.
      # @return [String] The markdown content with the grouping header removed,
      #   or the original if there are 0 or 2+ headings at the smallest level.
      def strip_grouping_header(markdown)
        # Collect all heading nodes with their levels
        heading_nodes = []
        min_level = nil
        Commonmarker.parse(markdown).walk do |node|
          next unless node.type == :heading

          heading_nodes << node
          min_level = node.header_level if min_level.nil? || node.header_level < min_level
        end
        # No headings at all — nothing to strip
        return markdown if heading_nodes.empty? || min_level.nil?

        # Find headings at the minimum level
        min_level_nodes = heading_nodes.select { |node| node.header_level == min_level }
        # Only strip when there is exactly 1 heading at the minimum level
        return markdown unless min_level_nodes.size == 1

        heading_node = min_level_nodes.first
        start_line = heading_node.source_position[:start_line] # 1-indexed
        # Only strip if it is on the top of the document
        return markdown unless start_line == 1

        end_line = heading_node.source_position[:end_line] # 1-indexed
        lines = markdown.lines.map(&:chomp)
        # Remove the heading lines (only the heading, not trailing blank lines that belong to content)
        (lines[0...(start_line - 1)] + lines[end_line..]).join("\n").strip
      end

      # Generate a Table of Contents (String) from a Markdown document string.
      #
      # @param markdown [String] The full Markdown document content.
      # @return [String] The generated Table of Contents as a Markdown list.
      def generate_table_of_contents(markdown)
        temp_file = "#{@session_dir}/tmp/content_to_be_toced.md"
        FileUtils.mkdir_p File.dirname(temp_file)
        File.write(temp_file, markdown)
        `npx doctoc --github --notitle --stdout #{temp_file}`.gsub(/==================\n.+$/m, '').strip
      end
    end
  end
end
