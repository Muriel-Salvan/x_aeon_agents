source 'https://rubygems.org'

gemspec

# The official cleanroom gem is not Ruby 3 compatible yet, so use the fork that
# handles keywords on the handle_kwargs branch.
# TODO: Remove this when the cleanroom gem will be compatible weith Ruby 3.
gem 'cleanroom', '~> 1.0',
    git: 'https://github.com/Muriel-Salvan/cleanroom',
    branch: 'handle_kwargs'

# Test dependencies
gem 'rspec', '~> 3.13'
gem 'rubocop', '~> 1.86'
gem 'rubocop-rspec', '~> 3.9'
gem 'rubocop-yard', '~> 1.1'
gem 'simplecov', '~> 0.22'
gem 'simplecov-cobertura', '~> 3.2'

# Deployment dependencies
gem 'sem_ver_components', '~> 0.4'
