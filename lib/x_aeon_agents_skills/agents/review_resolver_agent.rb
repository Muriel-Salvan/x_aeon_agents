module XAeonAgentsSkills
  module Agents
    # Agent responsible for addressing Pull Request review comments directed at X-Aeon Agents
    class ReviewResolverAgent < ComposableAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract
      prepend ComposableAgents::Mixins::Resumable
      prepend XAeonAgentsSkills::AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          pull_request_number: 'The Pull Request number to address comments for'
        }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {}
      end

      # Constructor
      #
      # @param kwargs [Hash<Symbol, Object>] Agent parameters
      def initialize(**kwargs)
        super(name: 'ReviewResolver', **kwargs)
      end

      # Execute the agent to address Pull Request review comments
      #
      # @param pull_request_number [Integer] The Pull Request number to address comments for
      # @return Hash<Symbol,Object> Output artifacts content
      def run(pull_request_number:)
        step(:gather_comments) do
          owner, repo = Helpers.github_repo.split('/')
          pr_json = Helpers.github.post(
            '/graphql',
            {
              query: File.read("#{__dir__}/../gh_comments.gql"),
              variables: {
                owner:,
                repo:,
                pr: pull_request_number
              }
            }.to_json
          )[:data][:repository][:pullRequest]
          @artifacts[:pr_conversations] = pr_json[:reviewThreads][:edges].select do |review_thread|
            !review_thread[:node][:isResolved] &&
              review_thread[:node][:comments][:nodes].any? do |comment|
                comment[:needAIReply] = comment[:body].start_with?('/agent') &&
                  comment_replies(review_thread[:node][:comments][:nodes], comment).none? { |reply| reply[:body].match(/^\[X-Aeon Agent \([^)]+\)\]/) }
                comment[:needAIReply]
              end
          end.map do |review_thread|
            review_thread[:node][:comments][:nodes].sort_by { |comment| comment[:createdAt] }.map do |comment|
              {
                comment_id: comment[:databaseId],
                created_at: comment[:createdAt],
                reply_to_comment_id: comment.dig(:replyTo, :databaseId),
                author: comment[:author][:login],
                body: comment[:body],
                path: comment[:path],
                need_ai_reply: comment[:needAIReply]
              }
            end
          end.to_json
        end

        pr_conversations = JSON.parse(@artifacts[:pr_conversations], symbolize_names: true)
        if pr_conversations.empty?
          log_debug "No PR reviews conversations found that need X-Aeon Agents input for PR ##{pull_request_number}"
        else
          log_debug "Found #{pr_conversations.size} PR reviews conversations that need X-Aeon Agents input for PR ##{pull_request_number}"
          open_comments_to_agents = pr_conversations.map do |conversation|
            conversation.select { |comment| comment[:need_ai_reply] }
          end.flatten(1)
          log_debug "Found #{open_comments_to_agents.size} PR review comments that need X-Aeon Agents to reply for PR ##{pull_request_number}"

          step(:extract_requirements) do
            pr = Helpers.github.pull_request(Helpers.github_repo, pull_request_number)
            feedback_analyst_agent = FeedbackAnalystAgent.new(**Models.free_complex_planning)
            step_agent(
              feedback_analyst_agent,
              pr_description: <<~EO_DESCRIPTION.strip,
                # #{pr.title}

                #{ComposableAgents::Utils::Markdown.align_markdown_headers(pr.body, level: 2)}
              EO_DESCRIPTION
              pr_files_diffs: Helpers.git.diff("#{pr.base.sha}...#{pr.head.sha}").to_s,
              conversations: JSON.dump(pr_conversations),
              open_comments_to_agents: JSON.dump(open_comments_to_agents),
              user_instructions: {
                ordered_list: [
                  <<~EO_INSTRUCTION,
                    Read the `#{feedback_analyst_agent.artifact_ref(:description)}` artifact to understand the purpose of this Pull Request

                    - This gives you context on what is the purpose of this Pull Request.
                  EO_INSTRUCTION
                  <<~EO_INSTRUCTION,
                    Read the `#{feedback_analyst_agent.artifact_ref(:pr_files_diffs)}` artifact to understand all changes made by this Pull Request

                    - This gives you context on how has this Pull Request been implemented.
                  EO_INSTRUCTION
                  <<~EO_INSTRUCTION,
                    Read the `#{feedback_analyst_agent.artifact_ref(:conversations)}` artifact to understand the full context of the PR conversations

                    - This gives you context on the discussions around this Pull Request.
                  EO_INSTRUCTION
                  <<~EO_INSTRUCTION,
                    Read the `#{feedback_analyst_agent.artifact_ref(:open_comments_to_agents)}` artifact to focus on agent-directed comments

                    - You must devise requirements that will address those exact comments.
                  EO_INSTRUCTION
                  <<~EO_INSTRUCTION,
                    Analyze agent-directed comments to identify specific requirements or tasks that need implementation
                  EO_INSTRUCTION
                  <<~EO_INSTRUCTION
                    Extract clear, actionable requirements from the comments in an artifact named `#{feedback_analyst_agent.artifact_ref(:requirements)}`

                    - If no implementation is required (e.g., comments are just questions), output "No requirements"
                  EO_INSTRUCTION
                ]
              }
            )
            @artifacts[:requirements] = 'No requirements' if @artifacts[:requirements].strip.downcase == 'no requirements'
          end

          if @artifacts[:requirements] == 'No requirements'
            @artifacts[:plan] = 'No implementation plan'
            @artifacts[:files_diffs] = 'No changes'
          else
            XAeonAgentsSkills::Agents.implement_requirements(@artifacts[:requirements], commit: true, pull_request: true)
          end

          open_comments_to_agents.each.with_index do |comment, comment_idx|
            step(:"reply_to_comment_#{comment_idx}") do
              review_responder_agent = ReviewResponderAgent.new(**Models.free_complex_planning)
              step_agent(
                review_responder_agent,
                open_comment_for_reply: JSON.pretty_generate(comment),
                user_instructions: {
                  ordered_list: [
                    <<~EO_INSTRUCTION,
                      Read the `#{review_responder_agent.artifact_ref(:conversations)}` artifact to understand the full context of the PR conversations

                      - This gives you context on the discussions around this Pull Request.
                    EO_INSTRUCTION
                    <<~EO_INSTRUCTION,
                      Read the `#{review_responder_agent.artifact_ref(:requirements)}` artifact to understand what was implemented

                      - This gives you context on what has been implemented by other agents.
                    EO_INSTRUCTION
                    <<~EO_INSTRUCTION,
                      Read the `#{review_responder_agent.artifact_ref(:plan)}` artifact to understand the implementation approach

                      - This gives you context on how other agents implemented the requirements.
                    EO_INSTRUCTION
                    <<~EO_INSTRUCTION,
                      Read the `#{review_responder_agent.artifact_ref(:files_diffs)}` artifact to understand the specific code changes made

                      - This gives you context on what files have been modified.
                    EO_INSTRUCTION
                    <<~EO_INSTRUCTION,
                      Read the `#{review_responder_agent.artifact_ref(:open_comment_for_reply)}` artifact to understand the specific comment to respond to

                      - This is the EXACT comment that you should reply to.
                    EO_INSTRUCTION
                    <<~EO_INSTRUCTION
                      Generate a professional, helpful reply that addresses the comment appropriately, in the artifact named `#{review_responder_agent.artifact_ref(:reply)}`

                      - If requirements were implemented, explain what was done and how it addresses the comment.
                      - If no requirements existed, provide a helpful response explaining the situation.
                    EO_INSTRUCTION
                  ]
                }
              )
              full_reply = "[X-Aeon Agent #{review_responder_agent.full_name}] - #{@artifacts[:reply]}"
              @artifacts[:replies] ||= []
              @artifacts[:replies] << { comment_id: comment[:comment_id], reply: full_reply }
              Helpers.github.create_pull_request_comment_reply(Helpers.github_repo, pull_request_number, full_reply, comment[:comment_id])
            end
          end
        end

        @artifacts
      end

      private

      # Get all the replies of a given comment.
      # Replies are:
      # - all the comments that have this comment as a direct reply,
      # - plus the next (closest next creation date) comment that replied to the parent of the given comment,
      # - plus all the replies of those replies (recursively).
      #
      # @param comments [Array<Hash>] All comments in the thread
      # @param comment [Hash] The comment to check for replies
      # @return [Array<Hash>] List of all the replies
      def comment_replies(comments, comment)
        comment_id = comment[:databaseId]
        # All direct replies
        replies = comments.select { |c| c.dig(:replyTo, :databaseId) == comment_id }
        # All replies to the same parent, sorted by creation date
        parent_comment_id = comment.dig(:replyTo, :databaseId)
        unless parent_comment_id.nil?
          created_at = Time.parse(comment[:createdAt])
          next_parent_reply = comments
            .select { |c| c.dig(:replyTo, :databaseId) == parent_comment_id && Time.parse(c[:createdAt]) > created_at }
            .min_by { |c| c[:created_at] }
          replies << next_parent_reply unless next_parent_reply.nil?
        end
        replies.map { |c| [c] + comment_replies(comments, c) }.flatten(1)
      end
    end
  end
end
