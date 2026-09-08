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
      # @param stub_handler [#call(agent, *args, **kwargs) -> Hash{Symbol => Object}, nil] Optional proc that receives the agent
      #   instance as the first argument followed by the +run+ args/kwargs.
      #   The return value becomes the return value of the stubbed +run+ (the mocked output artifacts).
      #   Defaults to a proc that sets a default message in conversation (when the agent has one) and returns no artifact.
      #   - Param agent [ComposableAgents::Agent] The agent that is being stubbed.
      #   - Param args [Array] All args that were given to the `run` method.
      #   - Param kwargs [Hash] All kwargs that were given to the `run` method.
      #   - Return [Hash{Symbol => Object}] The mocked output artifacts.
      # @param agent_classes [Array<Class>] Additional agent classes to be stubbed.
      #   As opposed to the base AI agent classes (stubbed with a prepend applying to the whole suite), those classes
      #   are stubbed with RSpec mocks scoped to the current example, so that other test cases keep running their
      #   real behavior. This is meant for orchestrator agents directly used by the code under test (eg. CLI commands),
      #   so that their run method does not execute for real but returns the mocked artifacts given by the stub handler.
      # @param agent_stub_block [#call(agent), nil] Optional block called with each stubbed agent instance from
      #   +agent_classes+ after its +run+ method has been stubbed. Use it to stub additional methods on the instance
      #   (e.g. methods returning co-author information) without resorting to +allow_any_instance_of+.
      #
      # @example Default stub (sets @conversation to a default message)
      #   stub_agent_run
      #   run_cli 'prompt', 'some text'
      #   expect(agent_run_calls.last[:kwargs]).to eq(user_instructions: 'some text')
      #
      # @example Custom handler that sets conversation on the agent and output artifacts
      #   stub_agent_run(
      #     stub_handler: lambda { |agent, user_instructions:, **|
      #       agent.track_message(message: 'fake reply', author: 'assistant')
      #       { tokens: 100 }
      #     }
      #   )
      def stub_agent_run(
        stub_handler: lambda { |agent, **_kwargs|
          agent.track_message(message: 'mocked AI response', author: 'assistant') if agent.respond_to?(:track_message)
          {}
        },
        agent_classes: [],
        agent_stub_block: nil
      )
        @agent_run_calls = []
        @agent_new_calls = []
        # Wire the prepended mixin's shared state to our test instance variables
        Stubs::PromptAgentsStubAgent.stub_handler = stub_handler
        Stubs::PromptAgentsStubAgent.run_calls = @agent_run_calls
        Stubs::PromptAgentsStubAgent.new_calls = @agent_new_calls
        # Stub all required agent classes
        [
          ComposableAgents::AiAgents::Agent,
          ComposableAgents::Cline::Agent
        ].each do |agent_class|
          agent_class.prepend(Stubs::PromptAgentsStubAgent) unless agent_class.ancestors.include?(Stubs::PromptAgentsStubAgent)
        end
        # Stub the extra agent classes with mocks scoped to the current example.
        # The real constructor is still executed (constructors are free of side effects), but the run
        # method returns the mocked artifacts of the stub handler instead of executing for real.
        agent_classes.each do |agent_class|
          next if agent_class.ancestors.include?(Stubs::PromptAgentsStubAgent)

          allow(agent_class).to receive(:new).and_wrap_original do |original_new, *args, **kwargs|
            agent = original_new.call(*args, **kwargs)
            Stubs::PromptAgentsStubAgent.record_new_call(agent, args, kwargs)
            allow(agent).to receive(:run) do |*run_args, **run_kwargs|
              filtered_artifacts = Stubs::PromptAgentsStubAgent.record_run_call(agent, run_args, run_kwargs)
              stub_handler.call(agent, *run_args, **filtered_artifacts)
            end
            agent_stub_block&.call(agent)
            agent
          end
        end
      end

      # @return [Array<Hash{Symbol => Object}>] Collector array for captured `run` calls. Each entry has the following properties:
      #   - agent [ComposableAgents::PromptDrivenAgent] The agent that received the call.
      #   - args [Array] All args given to the `run` method call.
      #   - kwargs [Hash] All kwargs given to the `run` method call.
      def agent_run_calls
        @agent_run_calls || []
      end

      # @return [Array<Hash{Symbol => Object}>] Collector array for captured `new` calls. Each entry has the following properties:
      #   - agent [ComposableAgents::PromptDrivenAgent] The agent that received the call.
      #   - args [Array] All args given to the `new` method call.
      #   - kwargs [Hash] All kwargs given to the `new` method call.
      def agent_new_calls
        @agent_new_calls || []
      end

      # Find the agent run calls of a specific agent class
      #
      # @param agent_class [Class] The agent class we are looking for
      # @param all [Boolean] Should we get all the run calls for this class, or just the first one?
      # @return [Array<Hash{Symbol => Object}>, Hash{Symbol => Object}, nil] Found matching run calls:
      #   - If `all` is true, returns an Array of all matching calls (see #agent_run_calls).
      #   - If `all` is false, returns the first matching call (see #agent_run_calls), or nil if none found.
      def find_run_calls_for(agent_class, all: false)
        matching_proc = proc { |run_call| run_call[:agent].is_a?(agent_class) }
        if all
          agent_run_calls.select(&matching_proc)
        else
          agent_run_calls.find(&matching_proc)
        end
      end

      # Find the agent new (constructor) calls of a specific agent class
      #
      # @param agent_class [Class] The agent class we are looking for
      # @param all [Boolean] Should we get all the new calls for this class, or just the first one?
      # @return [Array<Hash{Symbol => Object}>, Hash{Symbol => Object}, nil] Found matching new calls:
      #   - If `all` is true, returns an Array of all matching calls (see #agent_new_calls).
      #   - If `all` is false, returns the first matching call (see #agent_new_calls), or nil if none found.
      def find_new_calls_for(agent_class, all: false)
        matching_proc = proc { |new_call| new_call[:agent].is_a?(agent_class) }
        if all
          agent_new_calls.select(&matching_proc)
        else
          agent_new_calls.find(&matching_proc)
        end
      end
    end
  end
end
