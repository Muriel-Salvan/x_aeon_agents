require_relative 'shared_examples/agent_defaults'

describe XAeonAgents::AgentDefaults do
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

  # The AiAgents defaults
  it_behaves_like(
    'an agent using AgentDefaults',
    XAeonAgentsTest::Agents::TestAiAgent,
    configured_kwargs: { model: 'config-model' },
    expected_default_options: { strategy: ComposableAgents::PromptRenderingStrategy::Markdown },
    expected_default_options_kept: { strategy: ComposableAgents::PromptRenderingStrategy::Markdown },
    expected_singleton_modules: [ComposableAgents::PromptRenderingStrategy::Markdown]
  )

  # The normal Agents defaults
  it_behaves_like(
    'an agent using AgentDefaults',
    XAeonAgentsTest::Agents::TestAgent,
    configured_kwargs: { name: 'config-name' },
    expected_default_options: {},
    expected_default_options_kept: {}
  )
end
