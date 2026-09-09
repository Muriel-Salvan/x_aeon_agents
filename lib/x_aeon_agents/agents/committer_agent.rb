module XAeonAgents
  module Agents
    # Agent responsible for git committing locally staged or modified files
    class CommitterAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Constructor
      #
      # @param user_review [Boolean] Should the agent ask for user's git comment review?
      # @param stage [Symbol] Apply different staging strategies:
      #   - `all`: Always stage all files
      #   - `if_empty`: Stage all files only if the staging aread is empty
      #   - `none`: Don't stage anything
      # @param authors [Array<Agent>] List of agents that should be credited as authors of this commit
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(user_review: true, stage: :if_empty, authors: [], **agent_params)
        super(name: 'Committer', **agent_params)
        @user_review = user_review
        @stage = stage
        @authors = authors
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @return [Hash{Symbol => Object}] Output artifacts content
      def run
        super
        case @stage
        when :all
          task(:git_add, name: 'Git add', intent: 'Stage all modifications') do
            Helpers.git.add(all: true)
          end
        when :if_empty
          if Helpers.git_diff_cached.empty?
            task(:git_add, name: 'Git add', intent: 'Stage all modifications as nothing was staged previously') do
              Helpers.git.add(all: true)
            end
          end
        when :none
          # Do nothing
        else
          raise "Unknown staging strategy: #{@stage}"
        end
        if Helpers.git_diff_cached.empty?
          logger.info 'Nothing to commit'
        else
          git_diff_interpreter_agent = GitDiffInterpreterAgent.new
          task(git_diff_interpreter_agent, intent: 'Analyze staged git diffs', git_ref_base: 'cached')
          content = <<~EO_COMMIT
            #{@artifacts[:one_line_summary].strip}

            #{@artifacts[:change_intent].strip}

            Co-authored by X-Aeon AI Agents:
            #{
              (@authors + [git_diff_interpreter_agent.diff_interpreter_agent]).map do |agent|
                "* #{agent.full_name}"
              end.join("\n")
            }
          EO_COMMIT
          if @user_review
            task(:user_review, name: 'Commit comment user review', intent: 'Ask user to review the commit comment') do
              content, _user_prompt = Helpers.review_content(
                name: 'commit.md',
                description: 'Git commit comment',
                editable: true,
                content:
              )
            end
          end
          task(:git_commit, name: 'Git commit', intent: 'Create a commit') do
            Helpers.git.commit(content)
          end
          logger << 'Commit created successfully.'
        end
        {}
      end
    end
  end
end
