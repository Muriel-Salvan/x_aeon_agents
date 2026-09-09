require_relative 'shared_examples/agent_defaults'
require_relative 'shared_examples/status_usage'

describe XAeonAgents::AgentDefaults do
  describe 'Cline agents' do
    # The Cline agents defaults
    it_behaves_like(
      'an agent using AgentDefaults',
      XAeonAgentsTest::Agents::TestClineAgent,
      configured_kwargs: {
        model: 'config-model',
        cli_options: { thinking: 'low' }
      },
      expected_default_options: {
        api_key: 'test-cline-api-key',
        cli_options: { thinking: 'xhigh' }
      },
      expected_default_options_kept: { api_key: 'test-cline-api-key' },
      expected_singleton_modules: [ComposableAgents::PromptRenderingStrategy::MarkdownHeavy]
    )

    it_behaves_like(
      'a status displaying the usage of the run',
      XAeonAgentsTest::Agents::TestClineAgent
    )
  end
end
