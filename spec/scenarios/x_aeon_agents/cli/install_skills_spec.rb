describe XAeonAgents::Cli, '#install_skills' do
  before do
    stub_agent_run(agent_classes: [XAeonAgents::Agents::SkillInstallerAgent])
  end

  it 'installs skills for the default agent when no option is given' do
    run_cli 'install-skills'
    expect(find_run_calls_for(XAeonAgents::Agents::SkillInstallerAgent)[:kwargs]).to eq(agent: :cline)
  end

  it 'converts the agent name given with the --agent option to a symbol' do
    run_cli 'install-skills', '--agent', 'claude'
    expect(find_run_calls_for(XAeonAgents::Agents::SkillInstallerAgent)[:kwargs]).to eq(agent: :claude)
  end

  it 'transfers the session id given from the command line' do
    run_cli 'install-skills', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::SkillInstallerAgent)[:kwargs]).to eq(session_id: 'my-session')
  end
end
