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
    end
  end
end
