require_relative 'shared_examples/agent_configurability'

describe XAeonAgents::Cli, '#generate_skills' do
  # The generate-skills command uses the following agents:
  # - SkillGeneratorAgent
  around do |example|
    with_workspace { example.run }
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::SkillGeneratorAgent, 'generate-skills'
end
