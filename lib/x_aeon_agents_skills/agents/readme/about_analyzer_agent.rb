module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "About" section of a README.
      class AboutAnalyzerAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(about: 'The "About" section content in Markdown format, describing the project goal, problem it solves, and its interface')
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'About Analyzer',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's code, features and layout to understand its purpose and interface.
              Generate a high-level description of the project in Markdown format, compatible with Github flavor.
            EO_OBJECTIVE
            **agent_params
          )
        end
      end
    end
  end
end
