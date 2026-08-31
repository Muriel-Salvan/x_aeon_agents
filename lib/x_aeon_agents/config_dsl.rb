require 'cleanroom'

module XAeonAgents
  # Cleanroom-based DSL exposed by the optional .x_aeon_agents.rb config file.
  class ConfigDsl
    include Cleanroom

    # Set the debug mode.
    #
    # Parameters::
    # * *value* (Boolean): The debug mode to set
    def debug(value)
      Config.debug = value
    end

    expose :debug

    # Automatically expose a method per known secret name, allowing the config file
    # to define the code to retrieve this secret. The given block is stored as a Proc
    # and evaluated lazily only when the secret is needed.
    Config::KNOWN_SECRETS.each do |secret_name|
      # Define the code to retrieve a secret.
      #
      # Parameters::
      # * *retrieval_proc* (Proc): Code returning the secret value when evaluated
      define_method(secret_name) do |&retrieval_proc|
        Config.register_secret_proc(secret_name, retrieval_proc)
      end

      expose secret_name
    end
  end
end
