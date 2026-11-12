module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "Quick start" section of a README.
      class QuickStartAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            quick_start: {
              description: 'The "Quick start" section content in Markdown format, providing quick installation and usage instructions',
              type: :markdown
            }
          )
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Quick Start section generator',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's installation and usage patterns to provide quick installation and usage instructions.
              Generate a "Quick start" section in Markdown format, compatible with Github flavor.
              Focus on the precise steps that allow an external end user to use this project.
              For examples:
              - If this project is a Rubygem, explain how to install and use this Rubygem in an application.
              - If this project exposes CLI, explain how to install it in a user's system and how to invoke them.
              - If this project defines a web app, explain how to install this web app, run it and access it using a web browser.
              This section should be concise: don't cover all features, just simple install and startup guides for the main happy paths.
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
            '- Write only the required content to the output artifact file, without any additional header or title.',
            '- Do NOT write any explanation or description in the artifact file: write only the required content.',
            <<~EO_CONSTRAINT.rstrip,
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
            EO_CONSTRAINT
            "- This section is not meant for developers: don't describe how to develop, test, document, package or contribute to this project.",
            Helpers.repository_access_constraint,
            Helpers.artifacts_access_constraint(artifact_ref(:quick_start)),
            Helpers.non_interactive_constraint
          ].compact.join("\n")
        end
      end
    end
  end
end
