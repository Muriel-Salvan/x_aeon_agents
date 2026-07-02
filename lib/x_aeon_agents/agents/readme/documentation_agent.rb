module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "Documentation" section of a README.
      class DocumentationAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
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
            name: 'Documentation',
            objective: <<~EO_OBJECTIVE,
              Explore the project's documentation files and resources to identify all available documentation.
              Generate a "Documentation" section in Markdown format, compatible with Github flavor, providing links to documentation resources.
            EO_OBJECTIVE
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
