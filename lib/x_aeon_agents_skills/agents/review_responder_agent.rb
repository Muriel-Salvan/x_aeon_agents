module XAeonAgentsSkills
  module Agents
    # Agent responsible for generating a reply to a review comment
    class ReviewResponderAgent < ComposableAgents::Cline::Agent
      prepend XAeonAgentsSkills::AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        super.merge(
          {
            conversations: 'All PR conversations and comments to be considered (context)',
            open_comment_for_reply: 'The exact comment to be replied to',
            requirements: 'The requirements that have been implemented (or "No requirements")',
            plan: 'The implementation plan that was used to implement those requirements (or "No implementation plan")',
            files_diffs: 'The code changes from implement_requirements workflow (or "No changes")'
          }
        )
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {
          reply: {
            description: 'The exact reply text to post',
            type: :text
          }
        }
      end

      # Constructor
      #
      # @param agent_params [Hash<Symbol, Object>] Parameters driving the agent model selection
      def initialize(**agent_params)
        super(
          name: 'ReviewResponder',
          role: 'You are a review responder agent. Your role is to reply to feedback, taking into account the feedback itself, and the work that has been done because of this feedback.',
          objective: 'Generate a reply to a review comment',
          **agent_params
        )
        self.constraints = <<~EO_CONSTRAINTS
          - You are in read-only mode.
          - Do NOT modify or write any file.
          - The implementation work is already complete (captured in the artifacts).
          - ONLY focus on addressing the specific comment of the `#{artifact_ref(:open_comment_for_reply)}` artifact appropriately.
          - Do NOT answer or reply to any other comment.
          - You already have ALL the information required.
          - You MUST NOT ask follow-up questions.
          - You MUST NOT ask for user confirmation.
        EO_CONSTRAINTS
      end
    end
  end
end
