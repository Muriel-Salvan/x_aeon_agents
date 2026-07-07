module XAeonAgents
  # Mixin setting up default settings for agents.
  # This mixin is meant to be the last prepended mixin in all Agent classes.
  module AgentDefaults
    class << self
      # Get the singleton session ID.
      # If it is the first time it is invoked, use a default session ID.
      def singleton_session_id
        @singleton_session_id ||= Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S-%N')
      end
    end

    # Instantiate a new agent.
    # Transfer the same session to the new agent.
    #
    # @param agent_class [Class] The agent class to be instantiated
    # @param args [Array] Constructor parameters
    # @param kwargs [Hash] Constructor kwargs
    # @return [ComposableAgents::Agent] The new agent
    def new_agent(agent_class, *args, **kwargs)
      agent_class.new(*args, session_id: @session_id, **kwargs)
    end

    # Hook called when this mixin is prepended in a class
    #
    # @param base [Class] The base class prepending this mixin
    def self.prepended(base)
      base.prepend ComposableAgents::Mixins::ArtifactContract unless base.ancestors.include?(ComposableAgents::Mixins::ArtifactContract)
      base.prepend ComposableAgents::Mixins::Resumable unless base.ancestors.include?(ComposableAgents::Mixins::Resumable)
      # Make sure we always prepend at the top our initializer that sets all defaults
      base.prepend(
        Module.new do
          # Constructor
          #
          # @param args [Array] Agent's constructor arguments
          # @param session_id [String, nil] Specific X-Aeon session id to be used, or nil if none
          # @param kwargs [Array] Agent's constructor kwargs
          def initialize(*args, session_id: nil, **kwargs)
            # If we inherit from some frameworks initialize them now.
            Config.setup_composable_agents
            case self
            when ComposableAgents::AiAgents::Agent
              Config.setup_ai_agents
            when ComposableAgents::Cline::Agent
              Config.setup_cline
            end
            @session_id = session_id || AgentDefaults.singleton_session_id
            @session_dir = "#{Config.data_dir}/sessions/#{@session_id}"
            super(
              *args,
              composable_agents_dir: "#{@session_dir}/composable_agents",
              run_id: "#{@session_id}-#{kwargs[:name] || self.class.name.split('::').last}",
              **kwargs
            )
          end
        end
      )
    end
  end
end
