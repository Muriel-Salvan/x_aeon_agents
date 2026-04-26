require 'ruby_llm'
require 'agents'

module XAeonAgentsSkills
  # Singleton module to get all configuration of X-Aeon Agents
  module Configuration
    class << self
      include Logger

      attr_reader :config

      # Configure X-Aeon Agents
      #
      # Parameters::
      # @param cline_api_key [String] Cline API key to be used
      # @param openrouter_api_key [String] OpenRouter API key to be used
      # @param default_cline_model [String] Default Cline model
      # @param default_cline_config [Hash] Default Cline config
      # @param default_cline_cli_args [String] Default Cline CLI arguments
      # @param default_cline_skills [Array<string>] Default Cline skills
      # @param github_token [String] GitHub token for Octokit authentication
      # @param debug [Boolean] Do we activate debug mode?
      def configure(
        cline_api_key: ENV.fetch('CLINE_API_KEY', nil),
        openrouter_api_key: ENV.fetch('OPENROUTER_API_KEY', nil),
        default_cline_model: 'clinecli/arcee-ai/trinity-large-preview:free',
        default_cline_config: {
          actModeReasoningEffort: 'xhigh',
          autoApprovalSettings: {
            actions: {
              readFiles: true,
              readFilesExternally: true,
              editFiles: true,
              editFilesExternally: true,
              executeSafeCommands: true,
              executeAllCommands: true,
              useBrowser: true,
              useMcp: true
            },
            enabled: true
          },
          clineWebToolsEnabled: true,
          customPrompt: 'compact',
          defaultTerminalProfile: 'powershell-legacy',
          doubleCheckCompletionEnabled: true,
          enableParallelToolCalling: true,
          focusChainSettings: {
            enabled: true,
            remindClineInterval: 3
          },
          multiRootEnabled: false,
          nativeToolCallEnabled: true,
          planModeReasoningEffort: 'xhigh',
          planModeThinkingBudgetTokens: 1024,
          strictPlanModeEnabled: true,
          subagentsEnabled: true,
          telemetrySetting: 'disabled',
          useAutoCondense: true
        },
        default_cline_cli_args: '--thinking 1024',
        default_cline_skills: [],
        github_token: ENV.fetch('GITHUB_TOKEN', nil),
        debug: ENV['X_AEON_AGENTS_SKILLS_DEBUG'] == '1'
      )
        @config = {
          cline_api_key:,
          openrouter_api_key:,
          default_cline_model:,
          default_cline_config:,
          default_cline_cli_args:,
          default_cline_skills:,
          github_token:,
          debug:
        }

        # Register our providers
        RubyLLM::Provider.register(:clinecli, XAeonAgentsSkills::Providers::ClineCli)

        # Initialize our dependencies
        ENV['RUBYLLM_DEBUG'] = '1' if config[:debug]
        Logger.debug = config[:debug]
        ::Agents.configure do |ai_agents_config|
          ai_agents_config.debug = config[:debug]
        end
        RubyLLM.configure do |ruby_llm_config|
          ruby_llm_config.cline_api_key = config[:cline_api_key]
          ruby_llm_config.openrouter_api_key = config[:openrouter_api_key]
        end

        # Discover all the models
        RubyLLM::Models.refresh!
      end
    end
  end
end
