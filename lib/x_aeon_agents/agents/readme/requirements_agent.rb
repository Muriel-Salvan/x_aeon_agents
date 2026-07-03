module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "Requirements" section of a README.
      class RequirementsAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            requirements: {
              description: 'The "Requirements" section content in Markdown format, describing the prerequisites needed to use the project',
              type: :markdown
            }
          )
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Requirements',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's dependencies, runtime environment, and prerequisites.
              Generate a "Requirements" section in Markdown format, compatible with Github flavor, listing all prerequisites needed to use or run the project.
            EO_OBJECTIVE
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
