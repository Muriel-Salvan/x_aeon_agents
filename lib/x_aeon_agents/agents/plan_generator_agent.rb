module XAeonAgents
  module Agents
    # Agent responsible for producing detailed implementation plans from requirements
    class PlanGeneratorAgent < ComposableAgents::Cline::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        super.merge(
          requirements: {
            description: 'The initial requirements for which you need to devise an implementation plan',
            type: :markdown
          }
        )
      end

      # Define output artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        super.merge(
          plan: {
            description: 'The full and detailed implementation plan in Markdown format, ' \
              "that should implement the requirements given in the file `#{artifact_ref(:requirements)}`",
            type: :markdown
          }
        )
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(
          name: 'Plan generator',
          role: 'You are an implementation plan generator agent',
          objective: 'Produce a full and detailed implementation plan that can be used to implement some requirements.',
          system_instructions: <<~EO_INSTRUCTIONS,
            #{Helpers.repository_access_system_instructions}

            Always gather all the necessary context before starting to work on a task: read the relevant code, tests, documentation and configuration files of the repository.
            Begin by analyzing the user's input and gathering any necessary additional context.
            Review each question carefully and answer it with detailed, accurate information.
            If you need more information, use one of the available tools or ask for clarification instead of making assumptions or lies.
            Do not indicate that you will perform an action without actually doing it.
          EO_INSTRUCTIONS
          **agent_params
        )
        self.constraints = <<~EO_CONSTRAINTS
          - You are in read-only mode for the repository: do NOT modify any file of it.
          - You may only analyze and propose plans.
          - Do NOT execute the plan yourself.
          - #{Helpers.repository_access_constraint}
          - #{Helpers.artifacts_access_constraint(artifact_ref(:plan))}
        EO_CONSTRAINTS
      end
    end
  end
end
