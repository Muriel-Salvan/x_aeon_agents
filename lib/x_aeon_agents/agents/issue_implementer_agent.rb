module XAeonAgents
  module Agents
    # Agent responsible for implementing a GitHub issue using AI.
    class IssueImplementerAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        super.merge(
          github_issue_number: 'GitHub issue number to implement'
        )
      end

      # Constructor
      #
      # @param commit [Boolean] Whether to commit changes automatically
      # @param pull_request [Boolean] Whether to create a pull request automatically
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(commit: false, pull_request: false, **agent_params)
        super(name: 'Issue Implementer', **agent_params)
        @commit = commit
        @pull_request = pull_request
      end

      # Execute the agent to implement a GitHub issue.
      #
      # @param github_issue_number [Integer] The GitHub issue number
      # @return [Hash{Symbol => Object}] Output artifacts content
      def run(github_issue_number:)
        raise 'Unable to find the Github repository' unless Helpers.github_repo

        issue = Helpers.github.issue(Helpers.github_repo, github_issue_number)
        issue_comments = Helpers.github.issue_comments(Helpers.github_repo, github_issue_number)
        sections = [
          <<~EO_SECTION
            # #{issue.title}

            #{ComposableAgents::Utils::Markdown.align_markdown_headers(issue.body, level: 2)}
          EO_SECTION
        ]
        unless issue_comments.empty?
          sections << <<~EO_SECTION
            # Comments

            This is the conversation log that happened in this issue.
            This is provided as a reference to better understand the requirements.

            #{format_comments_for_artifact(issue_comments)}
          EO_SECTION
        end
        sections << <<~EO_SECTION
          # Associated Github issue

          - Number: #{issue.number}
          - Labels: #{issue.labels.map(&:name).join(', ')}
          - State: #{issue.state}
          - URL: #{issue.html_url}
        EO_SECTION
        step_agent(
          new_agent(DeveloperAgent, commit: @commit, pull_request: @pull_request),
          requirements: sections.map(&:strip).join("\n\n")
        )
        {}
      end

      private

      # Format issue comments for use in artifacts.
      #
      # @param comments [Array<Octokit::IssueComment>] Comments to format
      # @return [String] Formatted comments as markdown
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
