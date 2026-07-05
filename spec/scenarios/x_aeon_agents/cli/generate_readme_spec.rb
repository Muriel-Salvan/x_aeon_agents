describe XAeonAgents::Cli, '#generate_readme' do
  context 'when all sections are disabled' do
    it 'still succeeds and prints the success message' do
      stub_agent_run
      run_cli 'generate-readme',
              '--no-about',
              '--no-quick-start',
              '--no-requirements',
              '--no-features',
              '--no-public-api',
              '--no-documentation',
              '--no-how-it-works',
              '--no-development',
              '--no-contributing',
              '--no-license'
      expect(stdout).to include('README.md has been generated successfully.')
    end

    it 'does not create any Cline agent instances' do
      stub_agent_run
      run_cli 'generate-readme',
              '--no-about',
              '--no-quick-start',
              '--no-requirements',
              '--no-features',
              '--no-public-api',
              '--no-documentation',
              '--no-how-it-works',
              '--no-development',
              '--no-contributing',
              '--no-license'
      expect(agent_new_calls.size).to eq(0)
    end

    it 'uses the custom session directory with a custom session ID' do
      stub_agent_run
      run_cli 'generate-readme',
              '--no-about',
              '--no-quick-start',
              '--no-requirements',
              '--no-features',
              '--no-public-api',
              '--no-documentation',
              '--no-how-it-works',
              '--no-development',
              '--no-contributing',
              '--no-license',
              '--session-id',
              'my-custom-session'
      expect(stdout).to include('README.md has been generated successfully.')
    end
  end
end
