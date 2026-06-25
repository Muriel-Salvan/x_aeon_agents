module XAeonAgentsSkills
  module Agents
    # Agent responsible for creating a Pull Request of the current branch against its base reference on Github.
    class PullRequestCreatorAgent < ComposableAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract
      prepend XAeonAgentsSkills::AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          base_sha: 'The git ref of the base of the feature branch',
          requirements: 'The initial requirements'
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
      # @param authors [Array<Agent>] List of agents that should be credited as authors of this commit
      def initialize(authors: [])
        super(name: 'Pull Request Creator')
        @authors = authors
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param base_sha [String] The git reference of the base of the branch.
      # @param requirements [String] The initial requirements.
      # @return Hash<Symbol,Object> Output artifacts content
      def run(base_sha:, requirements:)
        repo_name = Helpers.github_repo
        head_branch = Helpers.git.current_branch

        # Push the branch on the git_remote using --force-with-lease as it may have been rebased
        # TODO: Use force_with_lease when it will be supported by ruby-git
        Helpers.git.push(Helpers.github_remote, head_branch, force: true)

        # Check if PR already exists for the current branch
        existing_pr = Helpers.github.pull_requests(repo_name, state: 'open').find { |pull_request| pull_request.head.ref == head_branch }
        if existing_pr.nil?
          # Create new PR
          git_diff_interpreter_agent = GitDiffInterpreterAgent.new
          git_diff_interpreter_agent_output = git_diff_interpreter_agent.run(git_ref_base: base_sha)
          sections = [git_diff_interpreter_agent_output[:change_intent].strip]
          sections << <<~EO_SECTION unless requirements.empty?
            # Initial requirements given

            #{ComposableAgents::Utils::Markdown.align_markdown_headers(requirements, level: 2)}
          EO_SECTION
          user_messages = @authors
            .map do |author|
              if author.respond_to?(:conversation)
                # Only keep single user prompts and agent's questions with their corresponding user's answer
                messages = []
                remaining_conversation = author.conversation.dup
                until remaining_conversation.empty?
                  message = remaining_conversation.shift
                  next if message[:message].strip.empty?

                  if message[:author] == 'User'
                    messages << message
                  elsif message[:question]
                    answer = remaining_conversation.first
                    messages <<
                      if answer && answer[:author] == 'User' && !answer[:message].strip.empty?
                        message.merge(answer: remaining_conversation.shift)
                      else
                        message
                      end
                  end
                end
                messages
              else
                []
              end
            end
            .flatten(1)
            .sort_by { |message| message[:at] }
          sections << <<~EO_SECTION unless user_messages.empty?
            # User guidance and feedback to agents

            #{
              messages
                .map do |message|
                  <<~EO_MESSAGE.strip
                    › **#{message[:author]}**
                    #{message[:message].each_line.map { |line| "> #{line}" }.join("\n")}
                    > <sub>#{message[:at]}</sub>
                    #{
                      if message[:answer]
                        <<~EO_ANSWER
                          >
                          > › **#{message[:answer][:author]}**
                          #{message[:answer][:message].each_line.map { |line| "> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;#{line}" }.join("\n")}
                          > &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<sub>#{message[:answer][:at]}</sub>
                        EO_ANSWER
                      end
                    }
                  EO_MESSAGE
                end
                .join("\n\n")
            }
          EO_SECTION
          sections << <<~EO_SECTION unless @authors.empty?
            # Co-authored by X-Aeon AI Agents

            #{
              (@authors + [git_diff_interpreter_agent.diff_interpreter_agent]).map do |agent|
                "* #{agent.full_name}"
              end.join("\n")
            }
          EO_SECTION
          new_pr = Helpers.github.create_pull_request(
            repo_name,
            'main',
            head_branch,
            git_diff_interpreter_agent_output[:one_line_summary].strip,
            sections.map(&:strip).join("\n\n")
          )
          log_debug "Created new Pull Request for branch #{head_branch}: #{new_pr.html_url}"
        else
          log_debug "A Pull Request for branch #{head_branch} already exists: #{existing_pr.html_url}"
        end
      end
    end
  end
end
