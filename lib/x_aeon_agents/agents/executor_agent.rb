module XAeonAgents
  module Agents
    class ExecutorAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::UserInteraction
      prepend AgentDefaults
    end
  end
end
