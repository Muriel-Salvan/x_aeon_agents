module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "Documentation" section of a README.
      class DocumentationAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            documentation: {
              description: 'The "Documentation" section content in Markdown format, providing links to documentation resources of the project',
              type: :markdown
            }
          )
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Documentation section generator',
            objective: <<~EO_OBJECTIVE,
              Explore the project's documentation files and resources to identify all available documentation.
              Generate a "Documentation" section in Markdown format, compatible with Github flavor, providing links to documentation resources.
            EO_OBJECTIVE
            system_instructions: <<~EO_INSTRUCTIONS,
              #{Helpers.repository_access_system_instructions}

              Always gather all the necessary context before starting to work on a task: explore the current repository's code, configuration and documentation to ground your analysis in the actual project.
              If you need more information, use one of the available tools instead of making assumptions.
              Do not indicate that you will perform an action without actually doing it.
            EO_INSTRUCTIONS
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
              - #{Helpers.repository_access_constraint}
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
