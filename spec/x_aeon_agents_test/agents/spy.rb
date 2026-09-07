module XAeonAgentsTest
  module Agents
    # Mixin spying on how the test agents of this namespace are constructed and called.
    # It centralizes all the getters/setters needed by tests to spy on the test agents.
    # It is included by the test agents, which record their constructor kwargs from their own
    # #initialize method: the recording must happen in the class's own constructor layer (below
    # the initializer prepended by AgentDefaults, which applies framework defaults, config DSL
    # procs and explicitly given kwargs, but above the framework classes consuming their own
    # kwargs).
    module Spy
      # @return [Hash{Symbol => Object}] The constructor kwargs received by the agent, ie. after
      #   the AgentDefaults mixin applied framework defaults, config DSL procs and explicit kwargs
      attr_accessor :received_kwargs

      # @return [String, nil] The run ID given to the agent (see ComposableAgents::Mixins::Resumable)
      attr_reader :run_id

      # The Proc stubbing the agent's run, to be set by test cases before running the agent.
      # It is evaluated in the context of the agent (using instance_exec), so it can define steps
      # and step_agent calls, and instantiate additional sub agents (setting their own run Proc
      # if they are also run through step_agent).
      #
      # @return [Proc, nil] The Proc stubbing the agent's run, or nil if not set yet
      attr_accessor :run_proc

      # Run the agent.
      # The framework-specific run implementations (AiAgents, Cline...) are bypassed, as test agents
      # only exist to validate the common behavior of all agents, not to invoke real AI providers.
      # The base agent's run bookkeeping (ie. run information creation) is still executed, so that
      # the status logging sees the run as a real one.
      # If a run Proc was set by the test case (see #run_proc), it is executed as the run's body,
      # and its result is returned. Otherwise, a completion message is logged: test agents have no
      # real processing to run, and this makes sure something gets logged so that the status can be
      # displayed in a TTY context.
      #
      # @param input_artifacts [Hash{Symbol => Object}] Input artifacts given to the run
      # @return [Hash{Symbol => Object}] The output artifacts of the run
      def run(**input_artifacts)
        # Execute only the base agent's run bookkeeping, so that the run is recorded like a real one.
        ComposableAgents::Agent.instance_method(:run).bind_call(self, **input_artifacts)
        if @run_proc
          instance_exec(**input_artifacts, &@run_proc)
        else
          logger.info "Agent #{full_name} has been run"
          {}
        end
      end

      # Expect the last status displayed on the test screen to be the given one.
      # Delegates to the currently running example's group instance, which holds the test screen and
      # the expectation helpers (this method is called from within the agent's run Proc, where the
      # agent itself has no access to them).
      #
      # @param expected_status [String] The exact expected status
      def expect_last_status_to_be(expected_status)
        RSpec.current_example.example_group_instance.expect_last_status_to_be(expected_status)
      end
    end
  end
end
