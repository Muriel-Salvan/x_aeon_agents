require 'agents'
require 'composable_agents'
require 'time'

module XAeonAgentsSkills
  # Helper methods to use agents
  module Agents
    class << self
      include Logger

      # Execute a simple task
      #
      # Parameters::
      # * *prompt* (String): The prompt for this task
      def execute_simple_task(prompt)
        agent = ExecutorAgent.new(**Models.free_simple)
        agent.run(user_message: prompt)
        puts agent.conversation.last[:message]
      end

      # Commit current code diffs.
      # If the staging area is empty, add everything.
      # Ask for a confirmation on the message from an editor.
      def commit
        CommitterAgent.new.run
      end

      # Generate the README.md file.
      # If the staging area is empty, add everything.
      # Ask for a confirmation on the message from an editor.
      #
      # @param run_id [String, nil] The associated run ID, or nil if no persistence needed.
      def generate_readme(run_id: nil)
        ReadmeGeneratorAgent.new(run_id:).run
      end

      # Interpret current code diffs
      #
      # Parameters::
      # * *git_ref_base* (Object): Git base (sha, objectish...) with which we diff [default = 'HEAD']
      # Result::
      # * String: Code diffs interpretation
      def interpret_diffs(git_ref_base = 'HEAD')
        git_diff_interpreter_agent_output = GitDiffInterpreterAgent.new.run(git_ref_base:)
        puts <<~EO_OUTPUT
          ===== Code diffs interpretation:

          #{git_diff_interpreter_agent_output[:one_line_summary].strip}

          #{git_diff_interpreter_agent_output[:change_intent].strip}
        EO_OUTPUT
      end

      # Implement a Github issue
      #
      # Parameters::
      # * *github_issue_number* (Integer): The Github issue number to implement
      # * *run_id* (String or nil): The associated run ID, or nil if no persistence needed [default: nil]
      def implement_github_issue(github_issue_number, run_id: nil)
        raise 'Unable to find the Github repository' unless Helpers.github_repo

        issue = Helpers.github.issue(Helpers.github_repo, github_issue_number)
        issue_comments = Helpers.github.issue_comments(Helpers.github_repo, github_issue_number)
        sections = [
          <<~EO_SECTION
            # #{issue.title}

            #{ComposableAgents::Utils::Markdown.align_markdown_headers(issue.body, level: 2)}
          EO_SECTION
        ]
        sections << <<~EO_SECTION unless issue_comments.empty?
          # Comments

          This is the conversation log that happened in this issue.
          This is provided as a reference to better understand the requirements.

          #{format_comments_for_artifact(issue_comments)}
        EO_SECTION
        sections << <<~EO_SECTION
          # Associated Github issue

          - Number: #{issue.number}
          - Labels: #{issue.labels.map(&:name).join(', ')}
          - State: #{issue.state}
          - URL: #{issue.html_url}
        EO_SECTION
        implement_requirements(sections.map(&:strip).join("\n\n"), run_id:, commit: true, pull_request: true)
      end

      # Implement some requirements, given a classic dev cycle:
      # 1. Planning
      # 2. Development
      # 3. Testing
      # 4. Documentation
      # 5. Releasing
      #
      # Parameters::
      # * *requirements* (String): Requirements to be implemented
      # * *run_id* (String or nil): The associated run ID, or nil if no persistence needed [default: nil]
      # * *commit* (Boolean): Do we commit changes? [default: false]
      # * *pull_request* (Boolean): Do we create a Pull Request (if not done already) for these requirements? [default: false]
      def implement_requirements(requirements, run_id: nil, commit: false, pull_request: false)
        DeveloperAgent.new(commit:, pull_request:, run_id:).run(requirements:)
      end

      # Address Pull Request comments by finding open PRs, extracting agent-directed comments,
      # implementing requirements, and replying to comments.
      #
      # Parameters::
      # * *pull_request_number* (Integer): The Pull Request number to address comments for
      # * *run_id* (String or nil): The associated run ID, or nil if no persistence needed [default: nil]
      def address_pull_request_comments(pull_request_number, run_id: nil)
        ReviewResolverAgent.new(run_id:).run(pull_request_number:)
      end

      private

      # Format comments for use in artifacts
      #
      # Parameters::
      # * *comments* (Array<Octokit::IssueComment>): Comments to format
      # Result::
      # * String: Formatted comments as markdown
      def format_comments_for_artifact(comments)
        return 'No comments' if comments.empty?

        comments.sort_by(&:created_at).map do |comment|
          <<~EO_COMMENT
            ## #{comment.user.login} at #{comment.created_at.utc.strftime('%F %T UTC')}

            #{ComposableAgents::Utils::Markdown.align_markdown_headers(comment.body, level: 3)}
          EO_COMMENT
        end.join("\n")
      end
    end
  end
end
