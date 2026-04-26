module XAeonAgentsSkills
  module Agents
    class ExecutorAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::UserInteraction
    end
  end
end
