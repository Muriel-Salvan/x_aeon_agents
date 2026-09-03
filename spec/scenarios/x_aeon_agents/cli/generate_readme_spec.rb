describe XAeonAgents::Cli, '#generate_readme' do
  before do
    stub_agent_run(agent_classes: [XAeonAgents::Agents::ReadmeGeneratorAgent])
  end

  it 'generates all sections with default arguments when no option is given' do
    run_cli 'generate-readme'
    expect(find_run_calls_for(XAeonAgents::Agents::ReadmeGeneratorAgent)[:kwargs]).to eq(
      gen_about: true,
      gen_quick_start: true,
      gen_requirements: true,
      gen_features: true,
      gen_public_api: true,
      gen_documentation: true,
      gen_how_it_works: true,
      gen_development: true,
      gen_contributing: true,
      gen_license: true
    )
  end

  it 'disables only the sections disabled from the command line' do
    run_cli 'generate-readme', '--no-features', '--no-license'
    expect(find_run_calls_for(XAeonAgents::Agents::ReadmeGeneratorAgent)[:kwargs]).to eq(
      gen_about: true,
      gen_quick_start: true,
      gen_requirements: true,
      gen_features: false,
      gen_public_api: true,
      gen_documentation: true,
      gen_how_it_works: true,
      gen_development: true,
      gen_contributing: true,
      gen_license: false
    )
  end

  it 'passes the custom README file path given with the --readme-file-path option' do
    run_cli 'generate-readme', '--readme-file-path', 'custom/README.md'
    expect(find_run_calls_for(XAeonAgents::Agents::ReadmeGeneratorAgent)[:kwargs]).to include(
      readme_file_path: 'custom/README.md'
    )
  end

  it 'transfers the session id given from the command line' do
    run_cli 'generate-readme', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::ReadmeGeneratorAgent)[:kwargs]).to eq(session_id: 'my-session')
  end
end
