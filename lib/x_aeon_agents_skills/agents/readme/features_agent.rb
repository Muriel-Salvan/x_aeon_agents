module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "Features" section of a README.
      class FeaturesAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(features: 'The "Features" section content in Markdown format, listing the key features of the project')
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Features',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's codebase and capabilities to identify all key features.
              Generate a "Features" section in Markdown format, compatible with Github flavor, listing the main features of the project.
            EO_OBJECTIVE
            **agent_params
          )
        end
      end
    end
  end
end
