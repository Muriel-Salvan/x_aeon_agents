module XAeonAgentsSkills
  module Agents
    # Agent responsible for producing detailed implementation plans from requirements
    class PlannerAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          requirements: 'Initial requirements for which you need to devise an implementation plan'
        }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {
          plan: 'Full and detailed implementation plan that should implement the requirements given by the artifact named `requirements`'
        }
      end

      # Constructor
      #
      # @param agent_params [Hash<Symbol, Object>] Parameters driving the agent model selection
      def initialize(**agent_params)
        super(
          name: 'Planner',
          role: 'You are a Planner agent',
          objective: 'Produce a full and detailed implementation plan that can be used to implement some requirements.',
          instructions: {
            ordered_list: [
              'Read the initial requirements from the artifact named `requirements`',
              'Analyze the project files',
              'Create an artifact named `plan` with a complete and detailed step-by-step implementation plan'
            ]
          },
          constraints: <<~EO_CONSTRAINTS,
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - You may only analyze and propose plans.
            - Do NOT execute the plan yourself.
          EO_CONSTRAINTS
          **agent_params
        )
      end
    end
  end
end
