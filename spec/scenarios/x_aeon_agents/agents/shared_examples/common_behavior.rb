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

    if agent_class.ancestors.include?(ComposableAgents::Mixins::UserInteraction)
      it 'returns the user answer when interactive mode is enabled' do
        XAeonAgents::Config.interactive = true
        allow($stdin).to receive(:gets).and_return("my answer\n")
        agent = agent_class.new
        expect(agent.ask('Question?')).to eq('my answer')
      end

      it 'returns a generic answer without prompting when interactive mode is disabled' do
        XAeonAgents::Config.interactive = false
        allow($stdin).to receive(:gets)
        agent = agent_class.new
        expect(agent.ask('Question?')).to eq(
          'You are running in non-interactive mode, so no human user is available to answer this question. ' \
            'Please continue using your best judgment and your existing knowledge to determine the most ' \
            'appropriate answer, and proceed with the task without further user input.'
        )
        expect($stdin).not_to have_received(:gets)
      end
    end
  end
end
