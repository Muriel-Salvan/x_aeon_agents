module XAeonAgentsTest
  module Helpers
    module InterpretGitDiffs
      # Stub the AI agent GitDiffInterpreterAgent.
      #
      # @param change_intent_message [String] The change intent message to be used
      def stub_git_diff_interpreter_agent(change_intent_message: 'Mocked change intent')
        @git_diff_interpreter_run_call = nil
        allow(XAeonAgents::Agents::GitDiffInterpreterAgent).to receive(:new).and_wrap_original do |original, *args, **kwargs|
          instance = original.call(*args, **kwargs)
          allow(instance).to receive(:run) do |**run_kwargs|
            @git_diff_interpreter_run_call = { agent: instance, kwargs: run_kwargs.slice(*instance.send(:input_artifacts_contracts).keys) }
            {
              change_intent: "#{change_intent_message} from base git ref #{run_kwargs[:git_ref_base]}",
              one_line_summary: "Mocked 1-line summary of changes from base #{run_kwargs[:git_ref_base]}"
            }
          end
          instance
        end
      end

      # @return [Hash{Symbol => Object}, nil] The last stubbed call to [XAeonAgents::Agents::GitDiffInterpreterAgent#run], or nil if none.
      #   Contains the following properties:
      #   - agent [XAeonAgents::Agents::GitDiffInterpreterAgent] The agent that got run.
      #   - kwargs [Hash] The kwargs given to the run call (filtered by the input artifacts contracts).
      attr_reader :git_diff_interpreter_run_call
    end
  end
end
