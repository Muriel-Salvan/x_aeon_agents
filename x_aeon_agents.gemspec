require_relative 'lib/x_aeon_agents/version'

Gem::Specification.new do |spec|
  spec.name          = 'x_aeon_agents'
  spec.version       = XAeonAgents::VERSION
  spec.summary       = 'AI agents skills to be used for X-Aeon projects'
  spec.homepage      = 'https://github.com/Muriel-Salvan/x_aeon_agents'
  spec.license       = 'BSD-3-Clause'

  spec.author        = 'Muriel Salvan'
  spec.email         = 'muriel@x-aeon.com'

  spec.files         = Dir['*.{md,txt}', '{lib}/**/*']
  spec.executables   = Dir['bin/*'].map { |exe_file| File.basename(exe_file) }
  spec.require_path  = 'lib'

  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'ai-agents', '~> 0.10'
  spec.add_dependency 'cleanroom', '~> 1.0'
  spec.add_dependency 'commonmarker', '~> 2.7'
  spec.add_dependency 'composable_agents', '~> 2.0'
  spec.add_dependency 'diffy', '~> 3.4'
  spec.add_dependency 'erb', '~> 6.0'
  spec.add_dependency 'front_matter_parser', '~> 1.0'
  spec.add_dependency 'git', '~> 4.3'
  spec.add_dependency 'human_number', '~> 0.1'
  spec.add_dependency 'json', '~> 2.18'
  spec.add_dependency 'launchy', '~> 3.1'
  spec.add_dependency 'octokit', '~> 10.0'
  spec.add_dependency 'pastel', '~> 0.8'
  spec.add_dependency 'ruby_llm', '~> 1.14'
  spec.add_dependency 'secret_string', '~> 1.1'
  spec.add_dependency 'sqlite3', '~> 2.9'
  spec.add_dependency 'thor', '~> 1.5'
  spec.add_dependency 'tty-cursor', '~> 0.7'
  spec.add_dependency 'tty-table', '~> 0.12'
  spec.add_dependency 'zeitwerk', '~> 2.7'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
