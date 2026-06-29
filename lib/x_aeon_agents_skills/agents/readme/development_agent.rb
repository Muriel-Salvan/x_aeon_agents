module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "Development" section of a README.
      class DevelopmentAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(development: 'The "Development" section content in Markdown format, explaining how to set up a development environment and contribute code')
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Development',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's development setup, build system, testing framework, and development workflows.
              Generate a "Development" section in Markdown format, compatible with Github flavor, explaining how to set up a development environment and contribute code.
            EO_OBJECTIVE
            **agent_params
          )
        end
      end
    end
  end
end
