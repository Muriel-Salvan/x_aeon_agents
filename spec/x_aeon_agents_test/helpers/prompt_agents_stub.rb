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
      #   Defaults to a proc that sets a default message in conversation and returns no artifact.
      #   - Param agent [ComposableAgents::PromptDrivenAgent] The agent that is being stubbed.
      #   - Param args [Array] All args that were given to the `run` method.
      #   - Param kwargs [Hash] All kwargs that were given to the `run` method.
      #   - Return [Hash{Symbol => Object}] The mocked output artifacts.
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
          agent.track_message(message: 'mocked AI response', author: 'assistant')
          {}
        }
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
    end
  end
end
