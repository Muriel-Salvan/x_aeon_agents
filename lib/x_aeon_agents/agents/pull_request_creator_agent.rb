module XAeonAgents
  module Agents
    # Agent responsible for creating a Pull Request of the current branch against its base reference on Github.
    class PullRequestCreatorAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          base_sha: 'The git ref of the base of the feature branch',
          requirements: {
            description: 'The initial requirements',
            optional: true
          }
        }
      end

      # Constructor
      #
      # @param authors [Array<Agent>] List of agents that should be credited as authors of this commit
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(authors: [], **agent_params)
        super(name: 'Pull Request Creator', **agent_params)
        @authors = authors
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param base_sha [String] The git reference of the base of the branch.
      # @param requirements [String, nil] The initial requirements, or nil if none.
      # @return [Hash{Symbol => Object}] Output artifacts content
      def run(base_sha:, requirements: nil)
        raise 'Unable to find the Github repository' unless Helpers.github_repo

        repo_name = Helpers.github_repo
        head_branch = Helpers.git.current_branch

        # Push the branch on the git_remote using --force-with-lease as it may have been rebased
        # TODO: Use force_with_lease when it will be supported by ruby-git
        Helpers.git.push(Helpers.github_remote, head_branch, force: true)

        # Check if PR already exists for the current branch
        existing_pr = Helpers.github.pull_requests(repo_name, state: 'open').find { |pull_request| pull_request.head.ref == head_branch }
        if existing_pr.nil?
          # Create new PR
          git_diff_interpreter_agent = new_agent(GitDiffInterpreterAgent)
          step_agent(git_diff_interpreter_agent, git_ref_base: base_sha)
          step(:create_pr) do
            sections = [@artifacts[:change_intent].strip]
            sections << <<~EO_SECTION if requirements
              # Initial requirements given

              #{ComposableAgents::Utils::Markdown.align_markdown_headers(requirements, level: 2)}
            EO_SECTION
            full_messages = @authors
              .map do |author|
                if author.respond_to?(:conversation)
                  # Only keep single user prompts and agent's questions with their corresponding user's answer
                  messages = []
                  # Skip the first user instruction
                  remaining_conversation =
                    if !author.conversation.empty? && author.conversation.first[:author].downcase == 'user'
                      author.conversation[1..]
                    else
                      author.conversation
                    end
                  until remaining_conversation.empty?
                    message = remaining_conversation.shift
                    next if message[:message].strip.empty?

                    if message[:author].downcase == 'user'
                      messages << message
                    elsif message[:question]
                      answer = remaining_conversation.first
                      messages <<
                        if answer && answer[:author].downcase == 'user' && !answer[:message].strip.empty?
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
            sections << <<~EO_SECTION unless full_messages.empty?
              # User guidance and feedback to agents

              #{
                full_messages
                  .map do |message|
                    <<~EO_MESSAGE.strip
                      › **#{message[:author]}**
                      #{message[:message].each_line.map { |line| "> #{line}".strip }.join("\n")}
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
                  "- #{agent.full_name}"
                end.join("\n")
              }
            EO_SECTION
            new_pr = Helpers.github.create_pull_request(
              repo_name,
              base_sha,
              head_branch,
              @artifacts[:one_line_summary].strip,
              sections.map(&:strip).join("\n\n")
            )
            # TODO: Make that a log_info
            log_debug "Created new Pull Request for branch #{head_branch}: #{new_pr.html_url}"
          end
        else
          # TODO: Make that a log_info
          log_debug "A Pull Request for branch #{head_branch} already exists: #{existing_pr.html_url}"
        end
        {}
      end
    end
  end
end
