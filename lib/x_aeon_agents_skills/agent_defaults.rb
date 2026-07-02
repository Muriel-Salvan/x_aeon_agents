module XAeonAgentsSkills
  # Mixin setting up default settings for agents.
  # This mixin is meant to be the last prepended mixin in all Agent classes.
  module AgentDefaults
    class << self
      # Get the singleton session ID.
      # If it is the first time it is invoked, use a default session ID.
      def singleton_x_aeon_session_id
        @singleton_x_aeon_session_id ||= Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S-%N')
      end
    end

    # Constructor
    #
    # @param args [Array] Agent's constructor arguments
    # @param x_aeon_session_id [String, nil] Specific X-Aeon session id to be used, or nil if none
    # @param kwargs [Array] Agent's constructor kwargs
    def initialize(*args, x_aeon_session_id: nil, **kwargs)
      @x_aeon_session_id = x_aeon_session_id || AgentDefaults.singleton_x_aeon_session_id
      @x_aeon_session_dir = ".x-aeon_agents/sessions/#{@x_aeon_session_id}"
      super(
        *args,
        composable_agents_dir: "#{@x_aeon_session_dir}/composable_agents",
        run_id: "#{@x_aeon_session_id}-#{kwargs[:name] || self.class.name.split('::').last}",
        **kwargs
      )
    end

    # Instantiate a new agent.
    # Transfer the same session to the new agent.
    #
    # @param agent_class [Class] The agent class to be instantiated
    # @param args [Array] Constructor parameters
    # @param kwargs [Hash] Constructor kwargs
    # @return [ComposableAgents::Agent] The new agent
    def new_agent(agent_class, *args, **kwargs)
      agent_class.new(*args, x_aeon_session_id: @x_aeon_session_id, **kwargs)
    end

    # Hook called when this mixin is prepended in a class
    #
    # @param base [Class] The base class prepending this mixin
    def self.prepended(base)
      base.prepend ComposableAgents::Mixins::ArtifactContract unless base.ancestors.include?(ComposableAgents::Mixins::ArtifactContract)
      base.prepend ComposableAgents::Mixins::Resumable unless base.ancestors.include?(ComposableAgents::Mixins::Resumable)
      # Make sure AgentDefaults is still first in the ancestors chain.
      # Avoid infinite loop here.
      base.prepend AgentDefaults unless base.ancestors.first == AgentDefaults
    end
  end
end
