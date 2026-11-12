module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "Features" section of a README.
      class FeaturesAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            features: {
              description: 'The "Features" section content in Markdown format, listing the key features of the project',
              type: :markdown
            }
          )
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Features section generator',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's codebase and capabilities to identify all key features.
              Generate a "Features" section in Markdown format, compatible with Github flavor, listing the main features of the project.
              Use emphasis, bullet points and small emojis to illustrate in a readable way the list of features.
              Don't provide an overall description of the project: another section is already doing it.
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
            Helpers.repository_access_constraint,
            Helpers.artifacts_access_constraint(artifact_ref(:features)),
            Helpers.non_interactive_constraint
          ].compact.join("\n")
        end
      end
    end
  end
end
