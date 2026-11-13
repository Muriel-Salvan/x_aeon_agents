require_relative 'shared_examples/agent_defaults'
require_relative 'shared_examples/status_usage'

describe XAeonAgents::AgentDefaults do
  describe 'AiAgents agents' do
    # The AiAgents defaults
    it_behaves_like(
      'an agent using AgentDefaults',
      XAeonAgentsTest::Agents::TestAiAgent,
      configured_kwargs: { model: 'config-model' },
      expected_default_options: { strategy: ComposableAgents::PromptRenderingStrategy::Markdown },
      expected_default_options_kept: { strategy: ComposableAgents::PromptRenderingStrategy::Markdown },
      expected_singleton_modules: [ComposableAgents::PromptRenderingStrategy::Markdown]
    )

    it_behaves_like(
      'a status displaying the usage of the run',
      XAeonAgentsTest::Agents::TestAiAgent
    )

    it 'does not constrain AiAgents agents to the use of the Cline tools' do
      expect(XAeonAgentsTest::Agents::TestAiAgent.new.constraints.to_s).not_to include('run_commands')
    end
  end
end
