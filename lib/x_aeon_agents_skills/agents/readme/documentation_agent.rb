module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "Documentation" section of a README.
      class DocumentationAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(documentation: 'The "Documentation" section content in Markdown format, providing links to documentation resources of the project')
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
            **agent_params
          )
        end
      end
    end
  end
end
