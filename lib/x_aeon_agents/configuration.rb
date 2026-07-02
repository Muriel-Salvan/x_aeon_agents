require 'ruby_llm'
require 'agents'

module XAeonAgents
  # Singleton module to get all configuration of X-Aeon Agents
  module Configuration
    class << self
      include Logger

      # @return [Hash{Symbol => Object}] The configuration
      attr_reader :config

      # Configure X-Aeon Agents
      #
      # Parameters::
      # @param cline_api_key [String] Cline API key to be used
      # @param openrouter_api_key [String] OpenRouter API key to be used
      # @param default_cline_cli_args [Hash{Symbol => Object}] Default Cline CLI arguments
      # @param github_token [String] GitHub token for Octokit authentication
      # @param debug [Boolean] Do we activate debug mode?
      def configure(
        cline_api_key: ENV.fetch('CLINE_API_KEY', nil),
        openrouter_api_key: ENV.fetch('OPENROUTER_API_KEY', nil),
        default_cline_cli_args: { thinking: 'xhigh' },
        github_token: ENV.fetch('GITHUB_TOKEN', nil),
        debug: ENV['X_AEON_AGENTS_DEBUG'] == '1'
      )
        @config = {
          cline_api_key:,
          openrouter_api_key:,
          default_cline_cli_args:,
          github_token:,
          debug:
        }

        # Initialize our dependencies
        if config[:debug]
          ENV['RUBYLLM_DEBUG'] = '1'
          ENV['COMPOSABLE_AGENTS_DEBUG'] = '1'
        end
        Logger.debug = config[:debug]
        ::Agents.configure do |ai_agents_config|
          ai_agents_config.debug = config[:debug]
        end
        RubyLLM.configure do |ruby_llm_config|
          ruby_llm_config.openrouter_api_key = config[:openrouter_api_key]
        end

        # Discover all the models
        RubyLLM::Models.refresh!
      end
    end
  end
end
