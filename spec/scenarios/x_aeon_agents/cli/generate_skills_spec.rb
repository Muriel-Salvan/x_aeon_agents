describe XAeonAgents::Cli, '#generate_skills' do
  # Mocked success value of the skills generation, overridable in contexts
  let(:skills_generation_success) { true }

  before do
    stub_agent_run(
      agent_classes: [XAeonAgents::Agents::SkillGeneratorAgent],
      stub_handler: lambda { |_agent, **_kwargs|
        { success: skills_generation_success }
      }
    )
  end

  it 'generates all skills in the default output directory when no option is given' do
    run_cli 'generate-skills'
    expect(find_run_calls_for(XAeonAgents::Agents::SkillGeneratorAgent)[:kwargs]).to eq(output_dir: 'skills', skill_names: nil)
  end

  it 'uses the output directory given with the --output-dir option' do
    run_cli 'generate-skills', '--output-dir', 'custom_skills'
    expect(find_run_calls_for(XAeonAgents::Agents::SkillGeneratorAgent)[:kwargs]).to eq(output_dir: 'custom_skills', skill_names: nil)
  end

  it 'generates only the skills given with repeated --skill options' do
    run_cli 'generate-skills', '--skill', 'name1', '--skill', 'name2'
    expect(find_run_calls_for(XAeonAgents::Agents::SkillGeneratorAgent)[:kwargs]).to eq(output_dir: 'skills', skill_names: %w[name1 name2])
  end

  it 'passes comma-separated skill names as a single --skill value' do
    run_cli 'generate-skills', '--skill', 'name1,name2'
    expect(find_run_calls_for(XAeonAgents::Agents::SkillGeneratorAgent)[:kwargs]).to eq(output_dir: 'skills', skill_names: ['name1,name2'])
  end

  it 'transfers the session id given from the command line' do
    run_cli 'generate-skills', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::SkillGeneratorAgent)[:kwargs]).to eq(session_id: 'my-session')
  end

  context 'when the skills generation failed' do
    let(:skills_generation_success) { false }

    it 'exits with a non-null status' do
      run_cli 'generate-skills', expect_failure: true
      expect(exit_status).to eq 1
    end
  end
end
