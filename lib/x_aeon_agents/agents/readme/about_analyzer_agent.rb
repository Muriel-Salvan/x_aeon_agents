module XAeonAgents
  module Agents
    # Collection of agents used to generate README parts
    module Readme
      # Agent responsible for generating the "About" section of a README.
      class AboutAnalyzerAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            about: {
              description: 'The "About" section content in Markdown format, describing the project goal, problem it solves, and its interface',
              type: :markdown
            },
            name: {
              description: 'This project\'s name',
              type: :text
            },
            description: {
              description: 'This project\'s description in 1 line',
              type: :markdown
            }
          )
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'About section generator',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's code, features and layout to understand its purpose and interface.
              Write the following information to the corresponding output artifact files:
              - The project's name (for example Rubygem's name, released package name, repository's name...).
              - The 1-line description of the project, using Markdown.
              - A high-level overview (about section) of the project in Markdown format, compatible with Github flavor.
            EO_OBJECTIVE
            system_instructions: <<~EO_INSTRUCTIONS,
              #{Helpers.repository_access_system_instructions}

              Always gather all the necessary context before starting to work on a task: explore the current repository's code, configuration and documentation to ground your analysis in the actual project.
              If you need more information, use one of the available tools instead of making assumptions.
              Do not indicate that you will perform an action without actually doing it.
            EO_INSTRUCTIONS
            **agent_params
          )
          self.constraints = [
            '- Write only the required content to the output artifact files, without any additional header or title.',
            '- Do NOT write any explanation or description in the artifact files: write only the required content.',
            <<~EO_CONSTRAINT.rstrip,
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
            EO_CONSTRAINT
            Helpers.repository_access_constraint,
            Helpers.cline_tools_constraint,
            Helpers.artifacts_access_constraint(artifact_ref(:about), artifact_ref(:name), artifact_ref(:description)),
            Helpers.non_interactive_constraint
          ].compact.join("\n")
        end
      end
    end
  end
end
