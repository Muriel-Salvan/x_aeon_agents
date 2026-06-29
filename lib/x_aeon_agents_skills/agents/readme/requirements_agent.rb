module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "Requirements" section of a README.
      class RequirementsAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(requirements: 'The "Requirements" section content in Markdown format, describing the prerequisites needed to use the project')
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
            **agent_params
          )
        end
      end
    end
  end
end
