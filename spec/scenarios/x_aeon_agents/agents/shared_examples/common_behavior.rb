# Shared examples validating that an agent class uses the common behavior shared by all agents,
# embodied by the AgentDefaults mixin (framework defaults, session properties, config DSL).
# The mixin behavior itself is fully tested in spec/scenarios/x_aeon_agents/agent_defaults_spec.rb,
# so validating its presence on the agent instance is enough.
#
# @param agent_class [Class] The agent class to be tested. It should be one of the agents from
#   XAeonAgents::Agents (or sub-namespaces), all having their constructors callable without arguments.
shared_examples 'an agent with common behavior' do |agent_class|
  describe "testing agent class #{agent_class}" do
    it 'has the AgentDefaults mixin prepended' do
      agent = agent_class.new
      expect(agent).to be_a(XAeonAgents::AgentDefaults)
    end
  end
end
