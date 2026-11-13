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
      mixins_to_prepend = [
        ComposableAgents::Mixins::ArtifactContract,
        ComposableAgents::Mixins::Retriable
      ]
      mixins_to_prepend << ComposableAgents::Mixins::RetriableArtifacts if base.ancestors.include?(ComposableAgents::PromptDrivenAgent)
      if base.ancestors.include?(ComposableAgents::Cline::Agent)
        mixins_to_prepend.push(
          ComposableAgents::Mixins::UserInteraction,
          ComposableAgents::Mixins::RetriableCline
        )
      end
      mixins_to_prepend << ComposableAgents::Mixins::AiAgentUserInteraction if base.ancestors.include?(ComposableAgents::AiAgents::Agent)
      mixins_to_prepend << ComposableAgents::Mixins::Resumable
      mixins_to_prepend.each { |mixin| base.prepend mixin unless base.ancestors.include?(mixin) }
      # Make sure we always prepend at the top our initializer that sets all defaults
      base.prepend(
        # TODO: Move this module into a dedicated mixin class and Ruby file.
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
            # Possible transformation applied to the agent's kwargs once the framework defaults,
            # the config DSL procs and the explicitly given kwargs are merged.
            kwargs_processor = proc { |agent_kwarg_hash| agent_kwarg_hash }
            kwargs_from_agent_defaults =
              case self
              when ComposableAgents::AiAgents::Agent
                Config.setup_ai_agents
                {
                  strategy: ComposableAgents::PromptRenderingStrategy::Markdown
                }
              when ComposableAgents::Cline::Agent
                Config.setup_cline
                # Default Cline CLI options bounding every agent run: no run can stall forever,
                # and consecutive mistakes are limited. Configured options supersede them.
                default_cline_cli_options = { timeout: 600, retries: 5 }
                # Whatever Cline global settings are configured (through the config DSL or explicitly),
                # always disable the Cline tools that are not used by X-Aeon agents: agents are
                # orchestrated by ComposableAgents (letting an LLM spawn agents or manage teams would
                # bypass this orchestration), and no human user answers questions in non-interactive mode.
                # Merge these tools with the configured ones, without duplicates.
                kwargs_processor = proc do |cline_agent_kwargs|
                  configured_global_settings = cline_agent_kwargs[:configure_global]
                  cline_agent_kwargs[:configure_global] = proc do |global_settings|
                    configured_global_settings&.call(global_settings)
                    disabled_tools = %w[
                      spawn_agent
                      team_attach_outcome_fragment
                      team_await_runs
                      team_broadcast
                      team_cancel_run
                      team_cleanup
                      team_create_outcome
                      team_finalize_outcome
                      team_list_outcomes
                      team_list_runs
                      team_mission_log
                      team_read_mailbox
                      team_review_outcome_fragment
                      team_run_task
                      team_send_message
                      team_shutdown_teammate
                      team_spawn_teammate
                      team_status
                      team_task
                      teams
                    ]
                    disabled_tools << 'ask_question' unless Config.interactive
                    global_settings.disabled_tools = disabled_tools | Array(global_settings.disabled_tools)
                  end
                  # Always bound Cline runs, while letting the configured CLI options supersede the
                  # defaults option by option (a nil value disables a default, as cline-rb skips nil options).
                  cline_agent_kwargs[:cli_options] = default_cline_cli_options.merge(cline_agent_kwargs[:cli_options] || {})
                  cline_agent_kwargs
                end
                {
                  api_key: Config.cline_api_key,
                  cli_options: Config.default_cline_cli_args.merge(default_cline_cli_options),
                  strategy: ComposableAgents::PromptRenderingStrategy::MarkdownHeavyFiles
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
            run_id = "#{@session_id}-#{kwargs[:name] || self.class.name.split('::').last}"
            agent_kwargs = kwargs_processor.call(kwargs_from_config.merge(kwargs))
            # TODO: Redesign how prompt rendering strategies are initialized with regard to the constructors and remove
            #   this code smell.
            # The prompt rendering strategy is included in the agent's singleton class by PromptDrivenAgent's
            # constructor, which runs after the agent's own constructor: include it here first so that the agent's
            # constructor and mixins can use the strategy's accessors (e.g. #artifact_ref) while being initialized.
            singleton_class.include(agent_kwargs[:strategy]) if agent_kwargs[:strategy]
            # File-based artifact strategies persist artifacts as files: give each agent run its own artifacts
            # directory so that agents of the same session don't share artifact files.
            self.artifacts_directory = "#{@session_dir}/composable_agents/runs/#{run_id}/artifacts" \
              if respond_to?(:artifacts_directory=)
            super(
              *args,
              composable_agents_dir: "#{@session_dir}/composable_agents",
              run_id:,
              logger: Config.logger,
              **agent_kwargs
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

          # Answer an agent's question
          #
          # @param question [String] The agent's question
          # @return [String] The answer that should be sent back to the agent
          def answer_to(question)
            if Config.interactive
              super
            else
              'You are running in non-interactive mode, so no human user is available to answer this question. ' \
                'Please continue using your best judgment and your existing knowledge to determine the most ' \
                'appropriate answer, and proceed with the task without further user input.'
            end
          end
        end
      )
    end
  end
end
