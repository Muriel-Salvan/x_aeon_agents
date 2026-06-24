module XAeonAgentsSkills
  # Mixin setting up default settings for agents.
  # This mixin is meant to be the last prepended mixin in all Agent classes.
  module AgentDefaults
    class << self
      # Get the singleton session ID.
      # If it is the first time it is invoked, use a default session ID.
      #
      # @param default_session_id [String, nil] The default session ID for the first time, or nil to allocate a unique new one.
      def x_aeon_session_id(default_session_id = nil)
        @x_aeon_session_id ||= default_session_id || Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S-%N')
      end
    end

    # Constructor
    #
    # @param args [Array] Agent's constructor arguments
    # @param x_aeon_session_id [String, nil] Specific X-Aeon session id to be used, or nil if none
    # @param kwargs [Array] Agent's constructor kwargs
    def initialize(*args, x_aeon_session_id: nil, **kwargs)
      @x_aeon_session_id = x_aeon_session_id || AgentDefaults.x_aeon_session_id(kwargs[:run_id])
      @x_aeon_session_dir = ".x-aeon_agents/sessions/#{@x_aeon_session_id}"
      super(*args, composable_agents_dir: "#{@x_aeon_session_dir}/composable_agents", **kwargs)
    end
  end
end
