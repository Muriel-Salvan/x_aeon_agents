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
        # @return [Array<Hash>] Collector for captured Agent#run calls
        attr_accessor :run_calls

        # @return [Array<Hash>] Collector for captured Agent.new calls
        attr_accessor :new_calls

        # @return [#call(agent, *args, **kwargs) -> Hash{Symbol => Object}, nil] Optional custom handler called by
        #   the stubbed +run+ method (see Helpers::PromptAgentsStub#stub_agent_run).
        attr_accessor :stub_handler
      end

      # Intercept Agent.new to capture constructor arguments, then let
      # the normal initialization chain proceed.
      # NOTE: AgentDefaults (prepended to subclasses) transforms session_id
      # into composable_agents_dir before this interceptor runs, so captured
      # kwargs reflect the post-AgentDefaults state.
      def initialize(*args, **kwargs)
        (PromptAgentsStubAgent.new_calls || []) << {
          agent: self,
          args: args,
          kwargs: kwargs
        }
        super
      end

      # Intercept Agent#run to capture call arguments, delegate to the
      # test's stub_handler (if any), and prevent real AI calls.
      def run(*args, **kwargs)
        (PromptAgentsStubAgent.run_calls || []) << {
          agent: self,
          args: args,
          kwargs: kwargs
        }
        PromptAgentsStubAgent.stub_handler ? PromptAgentsStubAgent.stub_handler.call(self, *args, **kwargs) : {}
      end

      # Track a message that is part of the conversation with this agent
      #
      # @param message [String, #to_hash, nil] The message content, as a String or an object that can be hashed, or nil if none.
      # @param author [String] Author of the message.
      # @param question [Boolean] Is this message a question expecting a reply?
      def track_message(message:, author: 'Orchestrator', question: false)
        super
      end
    end
  end
end
