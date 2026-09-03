require 'sawyer'

module XAeonAgentsTest
  module Helpers
    # Collection of test helpers on Github API and Octokit
    module Github
      # Mock Github API accessed using Octokit
      #
      # @param pull_requests [Array<Hash{Symbol => Object}>] List of Pull Request descriptions.
      #   Each hash can contain properties that are defined by `mock_pull_request` (see #mock_pull_request).
      def mock_github(pull_requests: [], issues: [])
        @github_double ||= instance_double(Octokit::Client)
        allow(Octokit::Client).to receive(:new).and_return(github_double)
        # Dynamically add the html_url on the singleton class of this specific object
        new_pr_instance = Sawyer::Resource.new(Sawyer::Agent.new(''))
        new_pr_instance.define_singleton_method(:html_url) { super }
        allow(github_double).to receive_messages(
          pull_requests: pull_requests.map do |pr_hash|
            data = { head: Sawyer::Resource.new(Sawyer::Agent.new(''), ref: pr_hash[:ref]) }
            data[:html_url] = pr_hash[:html_url] if pr_hash[:html_url]
            data[:number] = pr_hash[:number] if pr_hash[:number]
            Sawyer::Resource.new(Sawyer::Agent.new(''), **data)
          end,
          create_pull_request: object_double(new_pr_instance, html_url: 'https://github.com/owner/repo/pull/1')
        )
        # Mock the singular pull_request call and the GraphQL review comments query for each Pull Request.
        pull_requests.each { |pr_hash| mock_pull_request(**pr_hash) }
        # Mock the Github issue details (and their comments) for each issue.
        issues.each { |issue_hash| mock_github_issue(**issue_hash) }
      end

      # Mock a single Github issue and its comments.
      #
      # The IssueImplementerAgent calls +issue+ and +issue_comments+ on the Octokit client.
      # This helper stubs both, keyed on the 'owner/repo' slug and the issue number.
      #
      # @param number [Integer] The issue number
      # @param title [String] The issue title
      # @param body [String] The issue body
      # @param labels [Array<String>] The issue labels (as plain strings)
      # @param state [String] The issue state (e.g. 'open')
      # @param html_url [String] The issue URL
      # @param slug [String] The 'owner/repo' slug for the issue calls (defaults to matching any)
      # @param comments [Array<Hash{Symbol => Object}>] The issue comments (optional).
      #   Each comment can contain:
      #   - created_at [String] The comment creation timestamp
      #   - user_login [String] The comment author login
      #   - body [String] The comment body
      def mock_github_issue(
        number: 1,
        title: 'My Issue',
        body: 'Issue body description',
        labels: [],
        state: 'open',
        html_url: 'https://github.com/owner/repo/issues/1',
        slug: 'owner/repo',
        comments: []
      )
        allow(github_double).to receive(:issue).with(slug, number).and_return(
          Struct.new(:title, :body, :number, :labels, :state, :html_url).new(
            title,
            body,
            number,
            labels.map { |label| Struct.new(:name).new(label) },
            state,
            html_url
          )
        )
        allow(github_double).to receive(:issue_comments).with(slug, number).and_return(
          comments.map do |comment|
            Struct.new(:created_at, :user, :body).new(
              comment[:created_at],
              Struct.new(:login).new(comment[:user_login]),
              comment[:body]
            )
          end
        )
      end

      # Mock the singular pull_request call and the GraphQL review comments query for a single Pull Request.
      #
      # @param ref [String] The ref (branch name) of the Pull Request's head
      # @param html_url [String] The URL of the Pull Request
      # @param number [Integer] The Pull Request number
      # @param title [String] The Pull Request title
      # @param body [String] The Pull Request body
      # @param base_sha [String] The base commit SHA
      # @param head_sha [String] The head commit SHA
      # @param slug [String] The 'owner/repo' slug for the singular pull_request call (defaults to matching any)
      # @param review_comments [Array<Hash{Symbol => Object}>] List of review comments for this Pull Request (optional).
      #   When provided, mocks the POST to '/graphql' for the review comments query of this Pull Request.
      #   Each comment can contain:
      #   - databaseId [Integer] The comment database ID (optional, auto-assigned starting at 100 when omitted)
      #   - createdAt [String] The comment creation timestamp
      #   - body [String] The comment body
      #   - author [Hash] The comment author, with a :login key
      #   - path [String] The file path the comment is attached to
      #   - replyTo [Hash, nil] The replied-to comment, with a :databaseId key, or nil
      def mock_pull_request(
        ref: 'feature-branch',
        html_url: 'https://github.com/owner/repo/pull_requests/42',
        number: 42,
        title: 'My Pull Request',
        body: 'PR body description',
        base_sha: 'base-sha',
        head_sha: 'head-sha',
        slug: 'owner/repo',
        review_comments: []
      )
        allow(github_double).to receive(:pull_request).with(slug, number).and_return(
          Struct.new(:title, :body, :base, :head).new(
            title,
            body,
            Struct.new(:sha).new(base_sha),
            Struct.new(:sha).new(head_sha)
          )
        )

        # Mock the GraphQL review comments query for any Pull Request having a `review_comments` property,
        # building the expected GraphQL response from the provided list of comments.
        owner, repo = slug.split('/')
        allow(github_double).to receive(:post).with(
          '/graphql',
          a_string_including("\"owner\":\"#{owner}\"")
            .and(a_string_including("\"repo\":\"#{repo}\""))
            .and(a_string_including("\"pr\":#{number}"))
        ).and_return(
          {
            data: {
              repository: {
                pullRequest: {
                  reviewThreads: {
                    edges: [
                      {
                        node: {
                          isResolved: false,
                          comments: {
                            nodes: review_comments.each_with_index.map do |comment, idx|
                              {
                                databaseId: comment[:databaseId] || (100 + idx),
                                createdAt: comment[:createdAt],
                                body: comment[:body],
                                author: comment[:author],
                                path: comment[:path],
                                replyTo: comment[:replyTo]
                              }
                            end
                          }
                        }
                      }
                    ]
                  }
                }
              }
            }
          }
        )
      end

      # @return [Octokit, nil] The last mocked Github double, or nil if none
      attr_reader :github_double

      # Set up the git workspace of a complete Github Pull Request scenario for tests,
      # without mocking the Github API.
      #
      # Initializes a git workspace on a feature branch with an initial commit, then adds an
      # extra commit so the head SHA differs from the base SHA (simulating a normal Pull Request).
      # The real git SHAs are used so that git diff operations in the code under test do not fail.
      # They are recorded so that mock_github_pr can mock the Github API with the corresponding
      # Pull Request.
      #
      # As it performs no rspec-mocks stubbing, this helper is safe to be called from around
      # hooks (i.e. outside of the per-test mocks lifecycle), unlike with_github_pr.
      #
      # @yield Test code that will execute inside the git workspace.
      def with_github_pr_workspace
        with_git_workspace(
          files: { 'test.txt' => "original\n" },
          branch: 'feature-branch',
          remotes: { 'origin' => 'git@github.com:owner/repo.git' }
        ) do
          # Use the real git SHAs from the workspace so the git diff does not fail.
          # The base SHA is the initial commit (on the default branch).
          base_sha = ::Git.open(Dir.pwd).rev_parse('HEAD')
          # Add an extra commit on the feature branch to simulate a normal PR, so the head SHA differs from the base SHA.
          File.write('test.txt', "modified\n")
          git = ::Git.open(Dir.pwd)
          git.add('test.txt')
          git.commit('Add feature change')
          @github_pr_shas = { base_sha: base_sha, head_sha: git.rev_parse('HEAD') }
          yield
        end
      end

      # Mock the Github API for the Pull Request scenario set up by with_github_pr_workspace:
      # a single Pull Request (number 42, slug 'owner/repo') using the real git SHAs recorded
      # by with_github_pr_workspace, and stubs the reply-to-comment API so tests can assert on it.
      #
      # As it performs rspec-mocks stubbing, this helper must be called within the per-test
      # mocks lifecycle (from a before hook or an example body), not from around hooks.
      #
      # @param review_comments [Array<Hash{Symbol => Object}>] List of review comments to attach to the
      #   mocked Pull Request. Each comment can contain:
      #   - databaseId [Integer] The comment database ID (optional, auto-assigned starting at 100 when omitted)
      #   - createdAt [String] The comment creation timestamp
      #   - body [String] The comment body
      #   - author [Hash] The comment author, with a :login key
      #   - path [String] The file path the comment is attached to
      #   - replyTo [Hash, nil] The replied-to comment, with a :databaseId key, or nil
      def mock_github_pr(review_comments: [])
        raise 'Call with_github_pr_workspace before mock_github_pr' unless @github_pr_shas

        mock_github(
          pull_requests: [
            {
              ref: 'feature-branch',
              number: 42,
              slug: 'owner/repo',
              title: 'My Pull Request',
              body: 'PR body description',
              base_sha: @github_pr_shas[:base_sha],
              head_sha: @github_pr_shas[:head_sha],
              review_comments: review_comments
            }
          ]
        )
        allow(github_double).to receive(:create_pull_request_comment_reply)
      end

      # Set up a complete Github Pull Request scenario for tests.
      #
      # Convenience wrapper composing with_github_pr_workspace and mock_github_pr.
      # As mock_github_pr performs rspec-mocks stubbing, this helper must be called within
      # the per-test mocks lifecycle (from an example body), not from around hooks.
      #
      # @param review_comments [Array<Hash{Symbol => Object}>] List of review comments to attach to the
      #   mocked Pull Request (see mock_github_pr).
      # @yield Test code that will execute inside the git workspace, with the Github API mocked and
      #   the Pull Request reply API stubbed.
      def with_github_pr(review_comments: [])
        with_github_pr_workspace do
          mock_github_pr(review_comments: review_comments)
          yield
        end
      end
    end
  end
end
