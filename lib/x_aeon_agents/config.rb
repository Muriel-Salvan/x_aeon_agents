require 'agents'
require 'ruby_llm'
require 'secret_string'

module XAeonAgents
  # Singleton module to get all configuration of X-Aeon Agents
  module Config
    # TODO: Add test cases for this module
    class << self
      include Logger

      # Automatically generate accessors for secrets taken from the ENV or the Launcher
      %i[
        cline_api_key
        openrouter_api_key
        github_token
      ].each do |secret_name|
        # Set the secret from a string
        #
        # @param secret [String] The secret value
        define_method(:"#{secret_name}=") do |secret|
          @secrets ||= {}
          @secrets[secret_name] = SecretString.new(secret)
        end

        # Get the unprotected secret as a string.
        # Use defaults if the secret was never set.
        #
        # @return [String, nil] The secret value, or nil if none
        define_method(secret_name) do
          @secrets ||= {}
          @secrets[secret_name] ||= begin
            env_secret = ENV.fetch(secret_name.to_s.upcase, nil)
            env_secret ? SecretString.new(env_secret) : Helpers.keys_from_launcher[secret_name]
          end
          @secrets[secret_name]&.to_unprotected
        end
      end

      # @return [String] X-Aeon Agents data directory
      attr_writer :data_dir

      # @return [String] X-Aeon Agents data directory
      def data_dir
        @data_dir ||= '.x_aeon_agents'
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
