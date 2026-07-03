module XAeonAgentsTest
  module Stubs
    # Mixin prepended onto agent base classes to intercept
    # agent instantiation and method calls during tests. Because it is
    # prepended on the base class, all subclasses inherit the stubbed
    # behavior transparently while preserving their full mixin chain.
    #
    # This is the equivalent of "redefining the Agent class" in Ruby —
    # prepending onto the base class redefines behavior for all existing
    # and future subclasses without needing to reassign constants (which
    # cannot retroactively change subclass chains set at definition time).
    module PromptAgentsStubAgent
      class << self
        # @return [Array<Hash>] Fake conversation returned by Agent#conversation
        attr_accessor :conversation

        # @return [Array<Hash>] Collector for captured Agent#run calls
        attr_accessor :run_calls

        # @return [Array<Hash>] Collector for captured Agent.new calls
        attr_accessor :new_calls
      end

      # Intercept Agent.new to capture constructor arguments, then let
      # the normal initialization chain proceed.
      # NOTE: AgentDefaults (prepended to subclasses) transforms session_id
      # into composable_agents_dir before this interceptor runs, so captured
      # kwargs reflect the post-AgentDefaults state.
      def initialize(*args, **kwargs)
        (PromptAgentsStubAgent.new_calls || []) << { args: args, kwargs: kwargs }
        super
      end

      # Intercept Agent#run to capture call arguments, inject a fake
      # conversation, and prevent real AI calls.
      def run(*args, **kwargs)
        (PromptAgentsStubAgent.run_calls || []) << { args: args, kwargs: kwargs }
        @conversation = PromptAgentsStubAgent.conversation
        {}
      end
    end
  end
end
