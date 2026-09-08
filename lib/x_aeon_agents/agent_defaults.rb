module XAeonAgents
  # Mixin setting up default settings for agents.
  # This mixin is meant to be the last prepended mixin in all Agent classes.
  module AgentDefaults
    # Give all agents access to the shared logger instance.
    #
    # @return [Logger] The shared logger instance
    def logger
      Config.logger
    end

    class << self
      # @return [String] The singleton session ID. If it is the first time it is invoked, use a default session ID.
      def singleton_session_id
        @singleton_session_id ||= Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S-%N')
      end

      # @return [Array<Agent>] List of root agents (not instantiated from another agent).
      attr_accessor :root_agents
    end
    AgentDefaults.root_agents = []

    # Instantiate a new agent.
    # Transfer the same session to the new agent.
    #
    # @param agent_class [Class] The agent class to be instantiated
    # @param args [Array] Constructor parameters
    # @param kwargs [Hash] Constructor kwargs
    # @return [ComposableAgents::Agent] The new agent
    def new_agent(agent_class, *args, **kwargs)
      agent_class.new(*args, session_id: @session_id, parent_agent: self, **kwargs)
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
          # @param args [Array] Agent's constructor arguments.
          # @param session_id [String, nil] Specific X-Aeon session id to be used, or nil if none.
          # @param parent_agent [Agent, nil] Agent that is initializing this agent, or nil if none.
          # @param kwargs [Array] Agent's constructor kwargs.
          def initialize(*args, session_id: nil, parent_agent: nil, **kwargs)
            AgentDefaults.root_agents << self if parent_agent.nil?
            # If we inherit from some frameworks initialize them now.
            Config.setup_composable_agents
            kwargs_from_agent_defaults =
              case self
              when ComposableAgents::AiAgents::Agent
                Config.setup_ai_agents
                {
                  strategy: ComposableAgents::PromptRenderingStrategy::Markdown
                }
              when ComposableAgents::Cline::Agent
                Config.setup_cline
                {
                  api_key: Config.cline_api_key,
                  cli_options: Config.default_cline_cli_args
                }
              else
                {}
              end
            kwargs_from_config = kwargs_from_agent_defaults
            Config.agent_config_procs(self.class.name.split('::').last.to_sym).each do |config_proc|
              kwargs_from_config = kwargs_from_config.merge(config_proc.call(kwargs_from_config))
            end
            @session_id = session_id || AgentDefaults.singleton_session_id
            @session_dir = "#{Config.data_dir}/sessions/#{@session_id}"
            super(
              *args,
              composable_agents_dir: "#{@session_dir}/composable_agents",
              run_id: "#{@session_id}-#{kwargs[:name] || self.class.name.split('::').last}",
              logger: Config.logger,
              **kwargs_from_config.merge(kwargs)
            )
          end

          # Define a task that is resumable and that will log big steps of an agent.
          # A task can be nested in other tasks.
          #
          # @param task_ref [Symbol, ComposableAgents::Agent] Task reference: can be an ID or an Agent to be run.
          # @param name [String] Task name (used in status and logs).
          # @param intent [String] Task intent (used in logs).
          # @param kwargs [Hash{Symbol => Object}] Additional input artifacts to merge before the task executes.
          # @yield The code called for this task if it is not an Agent.
          def task(
            task_ref = :task,
            name: task_ref.is_a?(ComposableAgents::Agent) ? task_ref.name : task_ref.to_s,
            intent: 'Execute',
            **kwargs,
            &
          )
            @step_metadata = {
              name:,
              intent:
            }
            artifacts_before = @artifacts.clone
            logger.info "[Task #{name}] - #{intent}"
            if task_ref.is_a?(Symbol)
              step(task_ref, **kwargs, &)
            else
              step_agent(task_ref, **kwargs)
            end
            added_artifacts = @artifacts.keys - artifacts_before.keys
            logger.info "[Task #{name}] - Created #{added_artifacts.size} new artifacts: #{added_artifacts.join(', ')}"
          end

          private

          # Override record_step to inject the metadata into the step node.
          #
          # @param step_name [Symbol] Name of the step, mirroring the one used by the persisted steps.
          # @param agent [ComposableAgents::Agent, nil] The agent run by this step, or nil for plain steps.
          # @param extra_input_artifacts [Hash{Symbol => Object}] Input artifacts given to the step.
          # @yield The code of the step to be executed
          def record_step(step_name:, agent:, extra_input_artifacts:, &block)
            super do
              @current_step_node[:metadata] = @step_metadata if @step_metadata
              @step_metadata = nil
              block&.call
            end
          end
        end
      )
    end
  end
end
