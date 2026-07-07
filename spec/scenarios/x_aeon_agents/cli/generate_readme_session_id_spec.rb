describe XAeonAgents::Cli, '#generate_readme' do
  it 'does not regenerate the README when using --session-id on subsequent calls' do
    stub_doctoc
    stub_readme_generator_run
    run_readme_generator('--session-id', 'test-session-123')
    first_content = readme_content
    expect(first_content).to include('Generated content for quick_start')
    modified_content = first_content.gsub('Generated content for quick_start', 'Manually modified quick start')
    File.write(readme_path, modified_content)
    run_readme_generator('--session-id', 'test-session-123')
    expect(readme_content).to include('Manually modified quick start')
    run_readme_generator('--session-id', 'test-session-456')
    last_content = readme_content
    expect(last_content).not_to include('Manually modified quick start')
    expect(last_content).to include('Generated content for quick_start')
  end
end
