module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "Quick start" section of a README.
      class QuickStartAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(quick_start: 'The "Quick start" section content in Markdown format, providing quick installation and usage instructions')
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
            EO_OBJECTIVE
            **agent_params
          )
        end
      end
    end
  end
end
