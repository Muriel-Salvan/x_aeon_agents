require_relative 'shared_examples/agent_configurability'

describe XAeonAgents::Cli, '#install_skills' do
  # The install-skills command uses the following agents:
  # - SkillInstallerAgent
  around do |example|
    with_workspace { example.run }
  end

  before do
    # Prepare the minimal files expected by the skill installation flow, as the real skillkit CLI
    # is not available in the test environment.
    FileUtils.mkdir_p('.cline/skills/test_skill')
    File.write('.cline/skills/test_skill/SKILL.md', "# Test Skill\n")
    File.write('.cline/skills/test_skill/.skillkit.json', JSON.dump('subpath' => 'skills/test_skill'))

    # Stub the skillkit CLI commands executed by the agent. The manifest is stubbed with a first
    # block installing the test_skill (whose .skillkit.json subpath is already correct, and with no
    # dependencies), followed by a second block whose skills line is empty and thus instantiates no
    # further skill. The blank line between the two blocks is required for the manifest parsing.
    # The stub is placed on the agent instance so that the real run flow is preserved.
    allow(XAeonAgents::Agents::SkillInstallerAgent).to receive(:new).and_wrap_original do |original, **kwargs|
      agent_instance = original.call(**kwargs)
      allow(agent_instance).to receive(:`) do |cmd|
        raise "Unexpected backtick command: #{cmd}" unless cmd == 'skillkit manifest'

        "Skills:\n  - git@github.com:owner/skills-repo.git\n    skills: test_skill\n\n  - git@github.com:owner/skills-repo2.git\n    skills: \n"
      end
      allow(agent_instance).to receive(:system) do |cmd, **|
        raise "Unexpected system command: #{cmd}" unless cmd.include?('skillkit install')

        true
      end
      agent_instance
    end
  end

  it_behaves_like 'an agent configurable through the config DSL', XAeonAgents::Agents::SkillInstallerAgent, 'install-skills'
end
