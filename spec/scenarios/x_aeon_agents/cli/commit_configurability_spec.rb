require_relative 'shared_examples/agent_configurability'

describe XAeonAgents::Cli, '#commit' do
  # The commit command uses the following agents:
  # - CommitterAgent, which instantiates GitDiffInterpreterAgent, which itself instantiates
  #   OneLineCodeDiffSummarizerAgent and DiffInterpreterAgent.
  around do |example|
    with_git_workspace(files: { 'test.txt' => "original\n" }) do
      # Stage changes so that CommitterAgent instantiates GitDiffInterpreterAgent
      File.write('test.txt', "modified\n")
      `git add test.txt`
      example.run
    end
  end

  before do
    # Stub the interactive review of the commit message
    stub_review_content
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::CommitterAgent, 'commit'
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::GitDiffInterpreterAgent, 'commit'
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::OneLineCodeDiffSummarizerAgent, 'commit'
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DiffInterpreterAgent, 'commit'
end
