require_relative 'shared_examples/agent_configurability'

describe XAeonAgents::Cli, '#prompt' do
  # The prompt command uses the following agents:
  # - ExecutorAgent
  around do |example|
    with_workspace { example.run }
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::ExecutorAgent, 'prompt', 'test'
end
