module XAeonAgentsTest
  module Helpers
    module ReviewResolverAgent
      # Stub the FeedbackAnalystAgent and ReviewResponderAgent agents used by the
      # `review-comments` CLI flow, returning deterministic artifacts derived from the
      # agent-directed review comments.
      #
      # FeedbackAnalystAgent returns a synthesized set of requirements built from the
      # bodies of the open comments directed to the agents, while ReviewResponderAgent
      # returns a canned reply referencing the body of the comment being answered.
      #
      # Inputs are also echoed into each agent's conversation to ease debugging of the stub.
      #
      # @see #stub_agent_run
      def stub_review_resolver_agent
        stub_agent_run(
          stub_handler: lambda { |agent, **kwargs|
            case agent
            when XAeonAgents::Agents::FeedbackAnalystAgent
              # Echo the inputs back in the conversation for easier debugging of the stub.
              agent.track_message(message: "Feedback analysis from: #{kwargs[:open_comments_to_agents]}", author: 'assistant')
              {
                requirements: "Add a new validation method. Devised from: #{
                  kwargs[:open_comments_to_agents].map { |comment| "\"#{comment['body']}\"" }.join(', ')
                }."
              }
            when XAeonAgents::Agents::ReviewResponderAgent
              # Echo the inputs back in the conversation for easier debugging of the stub.
              agent.track_message(message: "Reply for comment: #{kwargs[:open_comment_for_reply]}", author: 'assistant')
              { reply: "Implemented the requested validation method. In response to: #{kwargs[:open_comment_for_reply]['body']}." }
            else
              {}
            end
          }
        )
      end
    end
  end
end
