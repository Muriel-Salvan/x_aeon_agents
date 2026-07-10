require 'sawyer'

module XAeonAgentsTest
  module Helpers
    # Collection of test helpers on Github API and Octokit
    module Github
      # Mock Github API accessed using Octokit
      #
      # @param pull_requests [Array<Hash{Symbol => String}>] List of Pull Request descriptions.
      #   Each hash can contain:
      #   - ref [String] The ref (branch name) of the Pull Request's head (required)
      #   - html_url [String] The URL of the Pull Request (optional)
      def mock_github(pull_requests: [])
        @github_double = instance_double(Octokit::Client)
        allow(Octokit::Client).to receive(:new).and_return(github_double)
        # Dynamically add the html_url on the singleton class of this specific object
        new_pr_instance = Sawyer::Resource.new(Sawyer::Agent.new(''))
        new_pr_instance.define_singleton_method(:html_url) { super }
        allow(github_double).to receive_messages(
          pull_requests: pull_requests.map do |pr_hash|
            data = { head: Sawyer::Resource.new(Sawyer::Agent.new(''), ref: pr_hash[:ref]) }
            data[:html_url] = pr_hash[:html] if pr_hash[:html]
            Sawyer::Resource.new(Sawyer::Agent.new(''), **data)
          end,
          create_pull_request: object_double(new_pr_instance, html_url: 'https://github.com/owner/repo/pull/1')
        )
      end

      # @return [Octokit, nil] The last mocked Github double, or nil if none
      attr_reader :github_double
    end
  end
end
