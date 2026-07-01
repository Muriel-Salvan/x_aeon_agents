require 'English'
require 'tmpdir'
require 'yaml'

RSpec.describe 'Gem packaging' do
  it 'successfully builds the gem and creates the correct file in specific test location' do
    Dir.mktmpdir do |temp_dir|
      gem_file = File.join(temp_dir, "composable_agents-#{ComposableAgents::VERSION}.gem")
      # Run gem build command with explicit output to our test directory
      stdout = `gem build composable_agents.gemspec --output #{gem_file}`

      expect($CHILD_STATUS.exitstatus).to eq(0)
      expect(stdout).to include('Successfully built RubyGem')
      # Verify the gem file was created with correct name and version
      expect(File).to exist(gem_file)
      expect(File.size(gem_file)).to be > 0

      # Verify generated gem specification
      lines = `gem specification #{gem_file}`.lines
      gem_spec = YAML.load(
        lines[(lines.index { |line| line.start_with?('---') })..].join,
        permitted_classes: [
          Gem::Specification,
          Gem::Version,
          Gem::Requirement,
          Gem::Dependency,
          Time,
          Symbol
        ]
      )
      expect(gem_spec.name).to eq('composable_agents')
      expect(gem_spec.version.to_s).to eq(ComposableAgents::VERSION)
    end
  end
end
