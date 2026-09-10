require 'bundler'

@safe_secrets = {
  cline_api_key: 'Muriel Salvan/AI/Cline/API Keys/VSCode and CLI',
  github_token: 'Muriel Salvan/Github/Tokens/Pushing my changes',
  openrouter_api_key: 'Muriel Salvan/AI/OpenRouter/API Keys/VSCodium'
}

# Retrieve API keys needed for the agents from the X-Aeon launcher
#
# @return [Hash{Symbol => SecretString}] The keys retrieved
def keys_from_launcher
  @keys_from_launcher ||= begin
    launcher_keys = {}
    Bundler.with_unbundled_env { `launcher safe -- #{@safe_secrets.values.map { |launcher_key| "\"#{launcher_key}\"" }.join(' ')}` }.each_line do |line|
      next unless line =~ /^\[PASSWORD\] \[([^\]]+)\]: (.+)$/

      launcher_keys[Regexp.last_match(1)] = SecretString.new(Regexp.last_match(2))
    end
    @safe_secrets.to_h { |key, launcher_key| [key, launcher_keys[launcher_key]] }
  end
end

@safe_secrets.each_key { |secret| send(secret) { keys_from_launcher[secret] } }

setup_project { system 'bundle install' }

test_project_cmd 'bundle exec rspec --format=documentation'

on_open_worktree { |dir| system "VSCodium.exe \"#{dir}\"" }

configure_agent(:PlanGeneratorAgent) do |agent_config|
  {
    skills: %w[
      applying-ruby-conventions
      applying-test-conventions
      enforcing-project-rules
    ],
    model: 'deepseek/deepseek-v4-flash',
    # Invoke Cline in plan mode, restricting Cline tools.
    cli_options: (agent_config[:cli_options] || {}).merge(plan: true),
    configure_global: proc do |global_settings|
      global_settings.disabled_tools = %w[editor run_commands]
    end
  }
end

configure_agent(:CoderAgent) do
  {
    skills: %w[
      applying-ruby-conventions
      applying-test-conventions
      enforcing-project-rules
    ],
    model: 'deepseek/deepseek-v4-flash'
  }
end

configure_agent(:TesterAgent) do
  {
    model: 'deepseek/deepseek-v4-flash'
  }
end

configure_agent(:DocumenterAgent) do
  {
    skills: %w[
      applying-ruby-conventions
      applying-test-conventions
      updating-doc
      enforcing-project-rules
    ],
    model: 'deepseek/deepseek-v4-flash'
  }
end

configure_agent(:OneLineCodeDiffSummarizerAgent) do
  {
    model: 'openrouter/free'
  }
end

configure_agent(:DiffInterpreterAgent) do
  {
    model: 'openrouter/free'
  }
end

configure_agent(:FeedbackAnalystAgent) do |agent_config|
  {
    skills: %w[
      applying-ruby-conventions
      applying-test-conventions
      enforcing-project-rules
    ],
    model: 'deepseek/deepseek-v4-flash',
    # Invoke Cline in plan mode, restricting Cline tools.
    cli_options: (agent_config[:cli_options] || {}).merge(plan: true),
    configure_global: proc do |global_settings|
      global_settings.disabled_tools = %w[editor run_commands]
    end
  }
end

configure_agent(:ReviewResponderAgent) do |agent_config|
  {
    model: 'deepseek/deepseek-v4-flash',
    # Invoke Cline in plan mode, restricting Cline tools.
    cli_options: (agent_config[:cli_options] || {}).merge(plan: true),
    configure_global: proc do |global_settings|
      global_settings.disabled_tools = %w[editor run_commands]
    end
  }
end

configure_agent(:ExecutorAgent) do
  {
    model: 'openrouter/free'
  }
end

%i[
  AboutAnalyzerAgent
  ContributingAgent
  DevelopmentAgent
  DocumentationAgent
  FeaturesAgent
  HowItWorksAgent
  LicenseAgent
  PublicApiAgent
  QuickStartAgent
  RequirementsAgent
].each do |readme_agent_class_name|
  configure_agent(readme_agent_class_name) do |agent_config|
    {
      model: 'deepseek/deepseek-v4-flash',
      # Invoke Cline in plan mode, restricting Cline tools.
      cli_options: (agent_config[:cli_options] || {}).merge(plan: true),
      configure_global: proc do |global_settings|
        global_settings.disabled_tools = %w[editor run_commands]
      end
    }
  end
end
