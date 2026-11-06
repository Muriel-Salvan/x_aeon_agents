module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "License" section of a README.
      class LicenseAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            license: {
              description: 'The "License" section content in Markdown format, describing the project license information',
              type: :markdown
            }
          )
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'License section generator',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's LICENSE file to identify the license type and terms.
              Generate a "License" section in Markdown format, compatible with Github flavor, describing the project license.
            EO_OBJECTIVE
            system_instructions: <<~EO_INSTRUCTIONS,
              #{Helpers.repository_access_system_instructions}

              Always gather all the necessary context before starting to work on a task: explore the current repository's code, configuration and documentation to ground your analysis in the actual project.
              If you need more information, use one of the available tools instead of making assumptions.
              Do not indicate that you will perform an action without actually doing it.
            EO_INSTRUCTIONS
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
              - #{Helpers.repository_access_constraint}
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
