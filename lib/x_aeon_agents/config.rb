require 'agents'
require 'ruby_llm'
require 'secret_string'

module XAeonAgents
  # Singleton module to get all configuration of X-Aeon Agents
  module Config
    # Name of the optional per-user / per-project configuration file
    CONFIG_FILE_NAME = '.x_aeon_agents.rb'

    # Possible secret names that can be configured and exposed in the config DSL
    KNOWN_SECRETS = %i[
      cline_api_key
      openrouter_api_key
      github_token
    ]

    class << self
      include Logger

      # @!group Public API

      # Automatically generate accessors for secrets taken from the ENV or the config DSL.
      # The precedence order is:
      # 1. Explicitly set with the corresponding accessor
      # 2. Taken from the ENV variable named after the secret (uppercased)
      # 3. Retrieved lazily by the Proc registered from the config DSL
      KNOWN_SECRETS.each do |secret_name|
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
          unless @secrets.key?(secret_name)
            @secrets[secret_name] =
              if (env_secret = ENV.fetch(secret_name.to_s.upcase, nil))
                SecretString.new(env_secret.dup)
              elsif @secret_procs&.key?(secret_name)
                proc_secret = @secret_procs[secret_name].call
                proc_secret.nil? ? nil : SecretString.new(proc_secret.dup)
              end
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

      # Candidate absolute paths of the configuration file, ordered by increasing
      # priority (lowest first): user home directory, then current directory.
      # This lets project settings override global ones.
      #
      # @return [Array<String>] The list of potential config paths
      def config_paths
        [
          # TODO: Add a path from the X_AEON_AGENTS_CONFIG env var too
          File.join(Dir.home, CONFIG_FILE_NAME),
          File.join(Dir.pwd, CONFIG_FILE_NAME)
        ]
      end

      # @return [AgentOptions] The available agent options.
      def agent_options
        @agent_options ||= AgentOptions.new
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

      # @!group Internal

      # Evaluate every configuration file existing at the candidate paths, from
      # the lowest priority (user/global) to the highest (current directory), so
      # that higher-priority files override lower-priority ones.
      def load
        config_paths.each do |config_file|
          ConfigDsl.new.evaluate_file(config_file) if File.exist?(config_file)
        end
      end

      # Register the Proc used to lazily retrieve a secret, called by the config DSL.
      # The Proc will be evaluated only when the secret is needed, and its result memoized.
      #
      # @param secret_name [Symbol] The secret name
      # @param retrieval_proc [Proc] The code to execute to retrieve the secret
      def register_secret_proc(secret_name, retrieval_proc)
        @secret_procs ||= {}
        @secret_procs[secret_name] = retrieval_proc
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
    end
  end
end
