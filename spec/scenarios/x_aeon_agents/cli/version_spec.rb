describe XAeonAgents::Cli, '#version' do
  it 'displays the x_aeon_agents version' do
    run_cli 'version'
    expect(stdout).to include("x_aeon_agents #{XAeonAgents::VERSION}")
  end

  it 'displays the version of each main library' do
    run_cli 'version'
    %w[ai-agents composable_agents cline-rb ruby_llm].each do |library|
      expected_version = Gem::Specification.find_by_name(library).version.to_s
      expect(stdout).to include("#{library}: #{expected_version}")
    end
  end

  it 'exits successfully' do
    run_cli 'version'
    expect(exit_status).to eq 0
  end
end
