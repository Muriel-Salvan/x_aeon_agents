module XAeonAgentsTest
  module Helpers
    module PromptAgentsStub
      # Stub an agent's #run method to prevent actual AI calls during tests.
      #
      # Prepends {XAeonAgentsTest::Stubs::PromptAgentsStubAgent} onto the given +agent_class+ so that
      # all subclasses inherit stubbed behavior transparently. This is the
      # equivalent of redefining the Agent class — all existing and future
      # subclasses use the stubbed initialize/run while preserving their full
      # mixin chain.
      #
      # @param conversation [Array<Hash>] Fake conversation to set on the agent
      #   after +run+ is called. Each hash MUST include a +:message+ key.
      # @param run_behavior [Proc, nil] Optional proc to customize the return
      #   value of the stubbed +run+ method. Called with the same +args+ and
      #   +kwargs+ passed to +run+. Defaults to +nil+, which returns +{}+.
      # @return [Array<Hash>] Collector array for captured run calls. Each entry
      #   is a Hash with +:args+ (positional) and +:kwargs+ (keyword) keys.
      #
      # @example Stub default behavior for all supported agents
      #   stub_agent_run
      #   run_cli 'prompt', 'some text'
      #   expect(last_agent_run_call[:kwargs]).to eq(user_instructions: 'some text')
      #
      # @example Custom run behavior
      #   stub_agent_run(
      #     run_behavior: ->(user_instructions:, **) { { tokens: 100 } }
      #   )
      def stub_agent_run(
        conversation: [{ message: 'mocked AI response' }],
        run_behavior: nil
      )
        @agent_run_calls = []
        @agent_new_calls = []

        # Wire the prepended mixin's shared state to our test instance variables
        Stubs::PromptAgentsStubAgent.conversation = conversation
        Stubs::PromptAgentsStubAgent.run_calls = @agent_run_calls
        Stubs::PromptAgentsStubAgent.new_calls = @agent_new_calls
        Stubs::PromptAgentsStubAgent.run_behavior = run_behavior

        # Stub all required agent classes
        [
          ComposableAgents::AiAgents::Agent,
          ComposableAgents::Cline::Agent
        ].each do |agent_class|
          agent_class.prepend(Stubs::PromptAgentsStubAgent) unless agent_class.ancestors.include?(Stubs::PromptAgentsStubAgent)
        end

        @agent_run_calls
      end

      # @return [Array<Hash>] All captured agent run calls since the last
      #   {#stub_agent_run} invocation, or an empty Array if none.
      def agent_run_calls
        @agent_run_calls || []
      end

      # @return [Hash, nil] The most recent captured agent run call, or nil.
      #   Hash keys: +:args+ (Array) and +:kwargs+ (Hash).
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
