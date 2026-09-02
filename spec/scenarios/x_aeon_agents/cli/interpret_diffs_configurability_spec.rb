require_relative 'shared_examples/agent_configurability'

describe XAeonAgents::Cli, '#interpret_diffs' do
  # The interpret-diffs command uses the following agents:
  # - GitDiffInterpreterAgent, which instantiates OneLineCodeDiffSummarizerAgent and
  #   DiffInterpreterAgent.
  around do |example|
    with_git_workspace(files: { 'test.txt' => "original content\n" }) { example.run }
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::GitDiffInterpreterAgent, 'interpret-diffs'
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::OneLineCodeDiffSummarizerAgent, 'interpret-diffs'
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DiffInterpreterAgent, 'interpret-diffs'
end
