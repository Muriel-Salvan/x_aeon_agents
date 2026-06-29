module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "How it works" section of a README.
      class HowItWorksAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(how_it_works: 'The "How it works" section content in Markdown format, explaining the internal architecture and working principles of the project')
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'How it works',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's architecture, design patterns, and internal workings.
              Generate a "How it works" section in Markdown format, compatible with Github flavor, explaining the internal architecture and working principles.
            EO_OBJECTIVE
            **agent_params
          )
        end
      end
    end
  end
end
