module XAeonAgents
  module Agents
    # Simple AI agent executing some prompt and interacting with the user
    class ExecutorAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::UserInteraction
      prepend AgentDefaults
    end
  end
end
