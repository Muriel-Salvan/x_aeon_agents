module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "Public API" section of a README.
      class PublicApiAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
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
            name: 'Public API section generator',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's codebase to identify all public APIs, classes, methods, and interfaces exposed to users.
              Generate a "Public API" section in Markdown format, compatible with Github flavor, documenting the public API surface.
            EO_OBJECTIVE
            system_instructions: <<~EO_INSTRUCTIONS,
              #{Helpers.repository_access_system_instructions}

              Always gather all the necessary context before starting to work on a task: explore the current repository's code, configuration and documentation to ground your analysis in the actual project.
              If you need more information, use one of the available tools instead of making assumptions.
              Do not indicate that you will perform an action without actually doing it.
            EO_INSTRUCTIONS
            **agent_params
          )
          self.constraints = [
            '- Write only the required content to the output artifact file, without any additional header or title.',
            '- Do NOT write any explanation or description in the artifact file: write only the required content.',
            <<~EO_CONSTRAINT.rstrip,
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
            EO_CONSTRAINT
            '- Only document public API entry points: executables and library public methods belonging to yarn `Public API` group.',
            Helpers.repository_access_constraint,
            Helpers.cline_tools_constraint,
            Helpers.artifacts_access_constraint(artifact_ref(:public_api)),
            Helpers.non_interactive_constraint
          ].compact.join("\n")
        end
      end
    end
  end
end
