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

      # Run the agent by executing the run Proc set by the test case.
      # This bypasses the real agent's run (which is not implemented by test agents), while still
      # going through the whole chain of prepended mixins (ie. the steps hierarchy recording of
      # AgentDefaults).
      #
      # @param input_artifacts [Hash{Symbol => Object}] Input artifacts given to the run
      # @return The result of the stubbed run
      # @raise [NotImplementedError] If no run Proc has been set on the agent
      def run(**input_artifacts)
        if @run_proc
          instance_exec(**input_artifacts, &@run_proc)
        else
          super
        end
      end
    end
  end
end
