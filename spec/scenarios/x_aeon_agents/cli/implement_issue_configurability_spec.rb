require_relative 'shared_examples/agent_configurability'

IMPLEMENT_ISSUE_CLI_CMD = %w[implement-issue 15]

describe XAeonAgents::Cli, '#implement_issue' do
  # The implement-issue command uses the following agents:
  # - IssueImplementerAgent, which instantiates DeveloperAgent (which instantiates PlannerAgent (which
  #   itself instantiates PlanGeneratorAgent), CoderAgent, TesterAgent, CommitterAgent, DocumenterAgent
  #   and PullRequestCreatorAgent). CommitterAgent and PullRequestCreatorAgent instantiate
  #   GitDiffInterpreterAgent, which itself instantiates OneLineCodeDiffSummarizerAgent and
  #   DiffInterpreterAgent.
  around do |example|
    with_git_workspace(
      files: { 'test.txt' => "original\n" },
      remotes: { 'origin' => 'git@github.com:owner/repo.git' }
    ) { example.run }
  end

  before do
    # Stub Launchy.open and $stdin.gets to avoid interactive prompts during plan review
    stub_review_content
    # Stub the test run command to fail once (so that TesterAgent gets instantiated), then succeed
    test_run_count = 0
    stub_command(
      'bundle exec rspec --format documentation',
      stdout: lambda do |_cmd|
        test_run_count += 1
        test_run_count <= 1 ? "Test failure ##{test_run_count}\n" : "All tests passed\n"
      end,
      exit_status: lambda do |_cmd|
        test_run_count <= 1 ? 1 : 0
      end
    )
    # Stub the Github issue to implement, and the git pushes and Pull Request creation
    mock_github(
      issues: [
        {
          number: 15,
          title: 'My Issue',
          body: 'Issue body description',
          labels: [],
          state: 'open',
          slug: 'owner/repo'
        }
      ]
    )
    mock_git_push
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::IssueImplementerAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DeveloperAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PlannerAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PlanGeneratorAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::CoderAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::TesterAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::CommitterAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DocumenterAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PullRequestCreatorAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::GitDiffInterpreterAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::OneLineCodeDiffSummarizerAgent, *IMPLEMENT_ISSUE_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DiffInterpreterAgent, *IMPLEMENT_ISSUE_CLI_CMD
end
