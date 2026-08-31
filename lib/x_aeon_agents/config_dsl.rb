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
  end
end
