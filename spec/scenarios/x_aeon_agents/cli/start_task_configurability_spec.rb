require_relative 'shared_examples/agent_configurability'

describe XAeonAgents::Cli, '#start_task' do
  # The start-task command uses the following agents:
  # - TaskStarterAgent
  around do |example|
    with_git_workspace(
      files: { 'test.txt' => "original\n" },
      remotes: { 'github' => 'git@github.com:owner/repo.git' }
    ) { example.run }
  end

  before do
    # Stub git pushes performed by the TaskStarterAgent, as there is no remote to push to in tests
    mock_git_push
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::TaskStarterAgent, 'start-task', '--branch', 'feature/configurability'
end
