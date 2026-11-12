module XAeonAgents
  module Agents
    # Simple AI agent executing some prompt and interacting with the user
    class ExecutorAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::UserInteraction
      prepend AgentDefaults

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(
          name: 'Executor',
          constraints: [
            Helpers.non_interactive_constraint
          ].compact.join("\n"),
          **agent_params
        )
      end
    end
  end
end
