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

        # Record an Agent.new (constructor) call in the new_calls collector.
        #
        # @param agent [ComposableAgents::Agent] The agent that was instantiated.
        # @param args [Array] All args that were given to the `new` method.
        # @param kwargs [Hash] All kwargs that were given to the `new` method.
        def record_new_call(agent, args, kwargs)
          (new_calls || []) << {
            agent:,
            args: args.map(&:clone),
            kwargs: kwargs.to_h { |k, v| [k, v.clone] }
          }
        end

        # Record an Agent#run call in the run_calls collector.
        # Only the kwargs belonging to the agent's input artifacts contracts are kept, like the
        # ArtifactContract mixin would do before executing the real +run+ method.
        #
        # @param agent [ComposableAgents::Agent] The agent that was run.
        # @param args [Array] All args that were given to the `run` method.
        # @param kwargs [Hash] All kwargs that were given to the `run` method.
        # @return [Hash] The kwargs filtered to the agent's input artifacts contracts.
        def record_run_call(agent, args, kwargs)
          filtered_artifacts = kwargs.slice(*agent.send(:input_artifacts_contracts).keys)
          (run_calls || []) << {
            agent:,
            args: args.map(&:clone),
            kwargs: filtered_artifacts.to_h { |k, v| [k, v.clone] }
          }
          filtered_artifacts
        end
      end

      # Intercept Agent.new to capture constructor arguments, then let
      # the normal initialization chain proceed.
      # NOTE: AgentDefaults (prepended to subclasses) transforms session_id
      # into composable_agents_dir before this interceptor runs, so captured
      # kwargs reflect the post-AgentDefaults state.
      def initialize(*args, **kwargs)
        PromptAgentsStubAgent.record_new_call(self, args, kwargs)
        super
      end

      # Intercept Agent#run to capture call arguments, delegate to the
      # test's stub_handler (if any), and prevent real AI calls.
      def run(*args, **kwargs)
        filtered_artifacts = PromptAgentsStubAgent.record_run_call(self, args, kwargs)
        PromptAgentsStubAgent.stub_handler ? PromptAgentsStubAgent.stub_handler.call(self, *args, **filtered_artifacts) : {}
      end

      # Make some methods public for spying.
      # Disable the cop checking for useless methods: those are useful to change visibility.

      # rubocop:disable Lint/UselessMethodDefinition

      # Track a message that is part of the conversation with this agent
      #
      # @param message [String, #to_hash, nil] The message content, as a String or an object that can be hashed, or nil if none.
      # @param author [String] Author of the message.
      # @param question [Boolean] Is this message a question expecting a reply?
      def track_message(message:, author: 'Orchestrator', question: false)
        # Redefine it to make it public so that stubs are easier to pilot.
        super
      end

      # Render instructions using the prompt rendering strategy.
      # Returns nil if instructions is nil.
      #
      # @param instructions [Object, nil] Instructions to render, or nil if none (see Instructions#initialize).
      # @return [String, nil] The rendered instructions, or nil if none
      def render_instructions(instructions)
        # Redefine it to make it public so that stubs are easier to pilot.
        super
      end

      # rubocop:enable Lint/UselessMethodDefinition
    end
  end
end
