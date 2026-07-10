module XAeonAgentsTest
  module Helpers
    # Collection of test helpers on Github API and Octokit
    module Github
      # Mock Github API accessed using Octokit
      #
      # @param pull_requests [Array] List of Pull Request objects to be mocked
      def mock_github(pull_requests: [])
        @github_double = instance_double(Octokit::Client)
        allow(Octokit::Client).to receive(:new).and_return(github_double)
        # Stub GitHub (Octokit) helpers: no existing PR found
        # Dynamically add the html_url on the singleton class of this specific object
        new_pr_instance = Sawyer::Resource.new(Sawyer::Agent.new(''))
        new_pr_instance.define_singleton_method(:html_url) { super }
        allow(github_double).to receive_messages(
          pull_requests:,
          create_pull_request: object_double(new_pr_instance, html_url: 'https://github.com/owner/repo/pull/1')
        )
      end

      # @return [Octokit, nil] The last mocked Github double, or nil if none
      attr_reader :github_double
    end
  end
end
