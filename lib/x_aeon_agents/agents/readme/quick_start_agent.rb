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
            name: 'Quick Start',
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
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
              - This section is not meant for developers: don't describe how to develop, test, document, package or contribute to this project.
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
