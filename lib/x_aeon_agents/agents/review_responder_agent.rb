module XAeonAgents
  module Agents
    # Agent responsible for generating a reply to a review comment
    class ReviewResponderAgent < ComposableAgents::Cline::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        super.merge(
          {
            conversations: {
              description: 'All PR conversations and comments to be considered (context)',
              type: :json
            },
            open_comment_for_reply: {
              description: 'The exact comment to be replied to',
              type: :json
            },
            requirements: {
              description: 'The requirements that have been implemented (or "No requirements")',
              type: :markdown
            },
            plan: {
              description: 'The implementation plan that was used to implement those requirements (or "No implementation plan")',
              type: :markdown
            },
            files_diffs: {
              description: 'The code changes from implement_requirements workflow (or "No changes")',
              type: :text
            }
          }
        )
      end

      # Define output artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        super.merge(
          reply: {
            description: 'The exact reply text to post',
            type: :text
          }
        )
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(
          name: 'Review feedback responder',
          role: 'You are a review responder agent. Your role is to reply to feedback, ' \
            'taking into account the feedback itself, and the work that has been done because of this feedback.',
          objective: 'Generate a reply to a review comment',
          system_instructions: <<~EO_INSTRUCTIONS,
            #{Helpers.repository_access_system_instructions}

            Always base your reply on the input artifacts given to you: they contain the full context of the Pull Request.
            Do not indicate that you will perform an action without actually doing it.
          EO_INSTRUCTIONS
          **agent_params
        )
        self.constraints = [
          '- You are in read-only mode for the repository: do NOT modify any file of it.',
          '- The implementation work is already complete (captured in the input artifacts).',
          "- ONLY focus on addressing the specific comment described in the file `#{artifact_ref(:open_comment_for_reply)}`.",
          '- Do NOT answer or reply to any other comment.',
          '- You already have ALL the information required.',
          '- You MUST NOT ask follow-up questions.',
          '- You MUST NOT ask for user confirmation.',
          "- Write the reply text to the output artifact file `#{artifact_ref(:reply)}`.",
          Helpers.repository_access_constraint,
          Helpers.artifacts_access_constraint(artifact_ref(:reply)),
          Helpers.non_interactive_constraint
        ].compact.join("\n")
      end
    end
  end
end
