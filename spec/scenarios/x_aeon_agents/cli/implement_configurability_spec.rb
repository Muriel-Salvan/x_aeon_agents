require_relative 'shared_examples/agent_configurability'

IMPLEMENT_CLI_CMD = ['implement', 'Add a new feature', '--commit', '--pr']

describe XAeonAgents::Cli, '#implement' do
  # The implement command uses the following agents:
  # - DeveloperAgent, which instantiates PlannerAgent (which itself instantiates PlanGeneratorAgent),
  #   CoderAgent, TesterAgent, CommitterAgent, DocumenterAgent and PullRequestCreatorAgent (the
  #   latter two being used only when the --commit / --pr options are given). CommitterAgent and
  #   PullRequestCreatorAgent instantiate GitDiffInterpreterAgent, which itself instantiates
  #   OneLineCodeDiffSummarizerAgent and DiffInterpreterAgent.
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
    # Stub the Github API and the git pushes needed by the --commit and --pr options
    mock_github
    mock_git_push
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DeveloperAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PlannerAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PlanGeneratorAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::CoderAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::TesterAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::CommitterAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DocumenterAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PullRequestCreatorAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::GitDiffInterpreterAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::OneLineCodeDiffSummarizerAgent, *IMPLEMENT_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DiffInterpreterAgent, *IMPLEMENT_CLI_CMD
end
