module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "Public API" section of a README.
      class PublicApiAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            public_api: {
              description: 'The "Public API" section content in Markdown format, describing the public API surface of the project',
              type: :markdown
            }
          )
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
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
              - Only document public API entry points: executables and library public methods belonging to yarn `Public API` group.
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
