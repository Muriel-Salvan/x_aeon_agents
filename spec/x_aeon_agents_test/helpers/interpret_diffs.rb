module XAeonAgentsTest
  module Helpers
    module InterpretDiffs
      # Stub the AI agents (DiffInterpreterAgent and OneLineCodeDiffSummarizerAgent).
      #
      # @param change_intent_message [String] The change intent message to be used
      def stub_diff_agents(change_intent_message: 'Mocked change intent from the following diffs')
        stub_agent_run(
          stub_handler: lambda { |agent, **kwargs|
            case agent
            when XAeonAgents::Agents::DiffInterpreterAgent
              {
                change_intent: <<~EO_ARTIFACT
                  #{change_intent_message}:
                  #{kwargs[:files_diff]}
                EO_ARTIFACT
              }
            when XAeonAgents::Agents::OneLineCodeDiffSummarizerAgent
              {
                one_line_summary: "1-line summary of \"#{kwargs[:change_intent].gsub("\n", ' ')}\""
              }
            else
              {}
            end
          }
        )
      end
    end
  end
end
