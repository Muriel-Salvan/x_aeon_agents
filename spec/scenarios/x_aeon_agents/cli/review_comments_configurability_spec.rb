require_relative 'shared_examples/agent_configurability'

REVIEW_COMMENTS_CLI_CMD = %w[review-comments 42]

describe XAeonAgents::Cli, '#review_comments' do
  # The review-comments command uses the following agents:
  # - ReviewResolverAgent, which instantiates FeedbackAnalystAgent, ReviewResponderAgent and
  #   DeveloperAgent (which instantiates PlannerAgent (which itself instantiates PlanGeneratorAgent),
  #   CoderAgent, TesterAgent, CommitterAgent, DocumenterAgent and PullRequestCreatorAgent).
  #   CommitterAgent and PullRequestCreatorAgent instantiate GitDiffInterpreterAgent, which itself
  #   instantiates OneLineCodeDiffSummarizerAgent and DiffInterpreterAgent.
  around do |example|
    # Set up the git workspace simulating the Pull Request. No mocking is performed here, as
    # around hooks run outside of the per-test rspec-mocks lifecycle.
    with_github_pr_workspace { example.run }
  end

  before do
    # Mock the Github API with the Pull Request carrying the agent-directed review comments,
    # and stub the reply-to-comment API
    mock_github_pr(
      review_comments: [
        {
          databaseId: 666,
          createdAt: '2024-01-01T10:00:00Z',
          body: '/agent Please add a validation method',
          author: { login: 'reviewer1' },
          path: 'lib/foo.rb',
          replyTo: nil
        }
      ]
    )
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
    # Stub the git pushes needed by the Pull Request creation of the development
    mock_git_push
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::ReviewResolverAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::FeedbackAnalystAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::ReviewResponderAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DeveloperAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PlannerAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PlanGeneratorAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::CoderAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::TesterAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::CommitterAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DocumenterAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::PullRequestCreatorAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::GitDiffInterpreterAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::OneLineCodeDiffSummarizerAgent, *REVIEW_COMMENTS_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::DiffInterpreterAgent, *REVIEW_COMMENTS_CLI_CMD
end
