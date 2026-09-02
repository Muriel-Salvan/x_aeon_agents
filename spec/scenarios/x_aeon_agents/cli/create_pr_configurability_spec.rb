require_relative 'shared_examples/agent_configurability'

describe XAeonAgents::Cli, '#create_pr' do
  # The create-pr command uses the following agents:
  # - PullRequestCreatorAgent, which instantiates GitDiffInterpreterAgent, which itself instantiates
  #   OneLineCodeDiffSummarizerAgent and DiffInterpreterAgent.
  around do |example|
    with_git_workspace(
      files: { 'test.txt' => "original\n" },
      branch: 'feature-branch',
      remotes: { 'origin' => 'git@github.com:owner/repo.git' }
    ) { example.run }
  end

  before do
    # Stub the Github API (no existing Pull Request, creation mocked) and the git pushes
    mock_github
    mock_git_push
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PullRequestCreatorAgent, 'create-pr'
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::GitDiffInterpreterAgent, 'create-pr'
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::OneLineCodeDiffSummarizerAgent, 'create-pr'
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DiffInterpreterAgent, 'create-pr'
end
