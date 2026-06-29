module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "Public API" section of a README.
      class PublicApiAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(public_api: 'The "Public API" section content in Markdown format, describing the public API surface of the project')
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Public API',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's codebase to identify all public APIs, classes, methods, and interfaces exposed to users.
              Generate a "Public API" section in Markdown format, compatible with Github flavor, documenting the public API surface.
            EO_OBJECTIVE
            **agent_params
          )
        end
      end
    end
  end
end
