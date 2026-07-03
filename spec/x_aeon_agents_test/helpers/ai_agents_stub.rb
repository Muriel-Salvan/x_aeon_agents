module XAeonAgentsTest
  module Helpers
    # Mixin prepended onto ComposableAgents::AiAgents::Agent to intercept
    # agent instantiation and method calls during tests. Because it is
    # prepended on the base class, all subclasses (ExecutorAgent,
    # DiffInterpreterAgent, etc.) inherit the stubbed behavior transparently
    # while preserving their full mixin chain (UserInteraction, AgentDefaults,
    # ArtifactContract, Resumable).
    #
    # This is the equivalent of "redefining the Agent class" in Ruby —
    # prepending onto the base class redefines behavior for all existing
    # and future subclasses without needing to reassign constants (which
    # cannot retroactively change subclass chains set at definition time).
    module AiAgentsStubAgent
      class << self
        # @return [Array<Hash>] Fake conversation returned by Agent#conversation
        attr_accessor :conversation

        # @return [Array<Hash>] Collector for captured Agent#run calls
        attr_accessor :run_calls

        # @return [Array<Hash>] Collector for captured Agent.new calls
        attr_accessor :new_calls
      end

      # Intercept Agent.new to capture constructor arguments, then let
      # the normal initialization chain (AgentDefaults, etc.) proceed.
      # NOTE: AgentDefaults (prepended to subclasses) transforms session_id
      # into composable_agents_dir before this interceptor runs, so captured
      # kwargs reflect the post-AgentDefaults state.
      def initialize(*args, **kwargs)
        (AiAgentsStubAgent.new_calls || []) << { args: args, kwargs: kwargs }
        super
      end

      # Intercept Agent#run to capture call arguments, inject a fake
      # conversation, and prevent real AI calls.
      def run(*args, **kwargs)
        (AiAgentsStubAgent.run_calls || []) << { args: args, kwargs: kwargs }
        @conversation = AiAgentsStubAgent.conversation
        {}
      end
    end

    module AiAgentsStub
      # Stub ComposableAgents::AiAgents::Agent#run to prevent actual AI calls
      # during tests.
      #
      # Prepends {AiAgentsStubAgent} onto the base ComposableAgents::AiAgents::Agent
      # class so that all subclasses (ExecutorAgent, DiffInterpreterAgent, etc.)
      # inherit stubbed behavior transparently. This is the equivalent of
      # redefining the Agent class — all existing and future subclasses use the
      # stubbed initialize/run while preserving their full mixin chain
      # (UserInteraction, AgentDefaults, ArtifactContract, Resumable).
      #
      # @param conversation [Array<Hash>] Fake conversation to set on the agent
      #   after `run` is called. Each hash MUST include a `:message` key.
      # @return [Array<Hash>] Collector array for captured run calls. Each entry
      #   is a Hash with `:args` (positional) and `:kwargs` (keyword) keys.
      #
      # @example Basic usage
      #   stub_agent_run(conversation: [{ message: 'Hello from AI' }])
      #   run_cli 'prompt', 'some text'
      #   expect(last_agent_run_call[:kwargs]).to eq(user_instructions: 'some text')
      def stub_agent_run(conversation: [{ message: 'mocked AI response' }])
        @agent_run_calls = []
        @agent_new_calls = []

        # Wire the prepended mixin's shared state to our test instance variables
        AiAgentsStubAgent.conversation = conversation
        AiAgentsStubAgent.run_calls = @agent_run_calls
        AiAgentsStubAgent.new_calls = @agent_new_calls

        # Prepend only once — RSpec may call stub_agent_run before each example
        ComposableAgents::AiAgents::Agent.prepend(AiAgentsStubAgent) unless
          ComposableAgents::AiAgents::Agent.ancestors.include?(AiAgentsStubAgent)

        @agent_run_calls
      end

      # @return [Array<Hash>] All captured agent run calls since the last
      #   {#stub_agent_run} invocation, or an empty Array if none.
      def agent_run_calls
        @agent_run_calls || []
      end

      # @return [Hash, nil] The most recent captured agent run call, or nil.
      #   Hash keys: `:args` (Array) and `:kwargs` (Hash).
      def last_agent_run_call
        agent_run_calls.last
      end

      # @return [Array<Hash>] All captured Agent.new calls since the last
      #   {#stub_agent_run} invocation, or an empty Array if none.
      def agent_new_calls
        @agent_new_calls || []
      end

      # @return [Hash, nil] The most recent captured Agent.new call, or nil.
      def last_agent_new_call
        agent_new_calls.last
      end
    end
  end
end
