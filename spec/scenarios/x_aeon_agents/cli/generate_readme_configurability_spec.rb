require_relative 'shared_examples/agent_configurability'

GENERATE_README_CLI_CMD = %w[generate-readme --readme-file-path README.md]

describe XAeonAgents::Cli, '#generate_readme' do
  # The generate-readme command uses the following agents:
  # - ReadmeGeneratorAgent, which instantiates one agent per README section.
  around do |example|
    with_workspace { example.run }
  end

  before do
    # Stub the doctoc command generating the table of contents
    stub_doctoc
    # Mock git remotes to generate the README badges from a fake test repository
    mock_git_remotes
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::ReadmeGeneratorAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::AboutAnalyzerAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::QuickStartAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::RequirementsAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::FeaturesAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::PublicApiAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::DocumentationAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::HowItWorksAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::DevelopmentAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::ContributingAgent, *GENERATE_README_CLI_CMD
  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::Readme::LicenseAgent, *GENERATE_README_CLI_CMD
end
