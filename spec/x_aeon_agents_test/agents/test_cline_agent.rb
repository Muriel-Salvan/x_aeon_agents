module XAeonAgentsTest
  module Agents
    # Cline-based test agent used to test the common behavior of all agents using AgentDefaults.
    class TestClineAgent < ComposableAgents::Cline::Agent
      prepend XAeonAgents::AgentDefaults
      include Spy

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Constructor kwargs as computed by the AgentDefaults mixin
      def initialize(**agent_params)
        self.received_kwargs = agent_params
        super
      end
    end
  end
end
