describe XAeonAgents::GenHelpers, '#tmp_path' do
  it 'returns the default temporary folder path for agents' do
    expect(process_erb('<%= tmp_path %>')).to eq File.expand_path('.x_aeon_agents_test/data/tmp')
  end
end
