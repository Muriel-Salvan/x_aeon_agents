module XAeonAgentsSkills
  module Agents
    class ExecutorAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::UserInteraction
      prepend XAeonAgentsSkills::AgentDefaults
    end
  end
end
