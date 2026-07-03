require 'ruby_llm'
require 'agents'

module XAeonAgents
  # Singleton module to get all configuration of X-Aeon Agents
  module Config
    class << self
      include Logger

      # @return [String] The Cline API key
      attr_writer :cline_api_key

      # @return [String] The Cline API key
      def cline_api_key
        @cline_api_key ||= ENV.fetch('CLINE_API_KEY', nil) || Helpers.keys_from_launcher[:cline_api_key]
      end

      # @return [String] The OpenRouter API key
      attr_writer :openrouter_api_key

      # @return [String] The OpenRouter API key
      def openrouter_api_key
        @openrouter_api_key ||= ENV.fetch('OPENROUTER_API_KEY', nil) || Helpers.keys_from_launcher[:openrouter_api_key]
      end

      # @return [String] The Github token
      attr_writer :github_token

      # @return [String] The Github token
      def github_token
        @github_token ||= ENV.fetch('GITHUB_TOKEN', nil) || Helpers.keys_from_launcher[:github_token]
      end

      # @return [Hash{Symbol => Object}] Default Cline CLI arguments
      attr_writer :default_cline_cli_args

      # @return [Hash{Symbol => Object}] Default Cline CLI arguments
      def default_cline_cli_args
        @default_cline_cli_args ||= { thinking: 'xhigh' }
      end

      # @return [Boolean] The debug mode
      def debug=(value)
        @debug = value
        Logger.debug = debug
      end

      # @return [Boolean] The debug mode
      def debug
        @debug ||= ENV['X_AEON_AGENTS_DEBUG'] == '1'
      end

      # Setup composable_agents in a lazy and memoized way
      def setup_composable_agents
        ENV['COMPOSABLE_AGENTS_DEBUG'] = '1' if debug
      end

      # Setup ai-agents in a lazy and memoized way
      def setup_ai_agents
        ENV['RUBYLLM_DEBUG'] = '1' if debug
        ::Agents.configure do |ai_agents_config|
          ai_agents_config.debug = debug
        end
        RubyLLM.configure do |ruby_llm_config|
          ruby_llm_config.openrouter_api_key = openrouter_api_key
        end
        # Discover all the models
        RubyLLM::Models.refresh!
      end

      # Setup Cline in a lazy and memoized way
      def setup_cline
        # Nothing to do
      end

      # Configure X-Aeon Agents
      #
      # @param kwargs [Hash] Any configuration property that can be set
      def configure(**kwargs)
        kwargs.each do |property, value|
          send(:"#{property}=", value)
        end
        Logger.debug = debug
      end
    end
  end
end
