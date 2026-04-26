module XAeonAgentsSkills
  module Agents
    # Agent responsible for git committing locally staged or modified files
    class CommitterAgent < ComposableAgents::Agent
      # Constructor
      #
      # @param user_review [Boolean] Should the agent ask for user's git comment review?
      # @param stage [Symbol] Apply different staging strategies:
      #   * all: Always stage all files
      #   * if_empty: Stage all files only if the staging aread is empty
      #   * none: Don't stage anything
      # @param authors [Array<Agent>] List of agents that should be credited as authors of this commit
      def initialize(user_review: true, stage: :if_empty, authors: [])
        super(name: 'Committer')
        @user_review = user_review
        @stage = stage
        @authors = authors
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param input_artifacts [Hash<Symbol,Object>] The input artifacts content
      # @return Hash<Symbol,Object> Output artifacts content
      def run(**_input_artifacts)
        case @stage
        when :all
          Helpers.git.add(all: true)
        when :if_empty
          Helpers.git.add(all: true) if Helpers.git_diff_cached.empty?
        when :none
          # Do nothing
        else
          raise "Unknown staging strategy: #{@stage}"
        end
        if Helpers.git_diff_cached.empty?
          log_debug 'Nothing to commit'
        else
          git_diff_interpreter_agent = GitDiffInterpreterAgent.new
          git_diff_interpreter_agent_output = git_diff_interpreter_agent.run(git_ref_base: 'cached')
          content = <<~EO_COMMIT
            #{git_diff_interpreter_agent_output[:one_line_summary].strip}

            #{git_diff_interpreter_agent_output[:change_intent].strip}

            Co-authored by X-Aeon AI Agents:
            #{
              (@authors + [git_diff_interpreter_agent.diff_interpreter_agent]).map do |agent|
                "* #{agent.name}#{" (#{agent.model})" if agent.respond_to?(:model)}"
              end.join("\n")
            }
          EO_COMMIT
          if @user_review
            content, _user_prompt = Helpers.review_content(
              name: 'commit.md',
              description: 'Git commit comment',
              editable: true,
              content:
            )
          end
          Helpers.git.commit(content)

          puts
          puts 'Commit created successfully.'
        end
      end
    end
  end
end
