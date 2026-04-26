module XAeonAgentsSkills
  module Agents
    # Agent responsible for implementing tasks following an implementation plan
    class CoderAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          plan: 'Implementation plan that you must follow'
        }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {}
      end

      # Constructor
      #
      # @param agent_params [Hash<Symbol, Object>] Parameters driving the agent model selection
      def initialize(**agent_params)
        super(
          name: 'Coder',
          role: 'You are a Coder agent',
          objective: 'Implement a task',
          instructions: <<~EO_INSTRUCTIONS,
            Follow all the steps of the implementation plan described in the artifact named `plan`.
          EO_INSTRUCTIONS
          **agent_params
        )
      end
    end
  end
end
