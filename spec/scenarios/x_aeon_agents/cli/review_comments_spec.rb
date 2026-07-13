describe XAeonAgents::Cli, '#review_comments' do
  describe 'with review comments addressed to the agents' do
    # Input artifacts captured from DeveloperAgent#run, for assertions in the test scenarios.
    #
    # @return [Hash{Symbol => Object}, nil] The keyword arguments DeveloperAgent#run was last called with, or nil
    attr_reader :dev_run_kwargs

    before do
      stub_agent_run(
        stub_handler: lambda { |agent, **kwargs|
          case agent
          when XAeonAgents::Agents::FeedbackAnalystAgent
            # Echo the inputs back in the conversation for easier debugging of the stub.
            agent.track_message(message: "Feedback analysis from: #{kwargs[:open_comments_to_agents]}", author: 'assistant')
            {
              requirements: "Add a new validation method. Devised from: #{
                kwargs[:open_comments_to_agents].map { |comment| "\"#{comment['body']}\"" }.join(', ')
              }."
            }
          when XAeonAgents::Agents::ReviewResponderAgent
            # Echo the inputs back in the conversation for easier debugging of the stub.
            agent.track_message(message: "Reply for comment: #{kwargs[:open_comment_for_reply]}", author: 'assistant')
            { reply: "Implemented the requested validation method. In response to: #{kwargs[:open_comment_for_reply]['body']}." }
          else
            {}
          end
        }
      )

      # DeveloperAgent inherits from ComposableAgents::Agent directly, so it is not covered by
      # stub_agent_run (which only stubs ComposableAgents::AiAgents::Agent and ComposableAgents::Cline::Agent).
      # Mock it (new and run) explicitly, capturing its run input artifacts for assertions.
      @dev_run_kwargs = nil
      allow(XAeonAgents::Agents::DeveloperAgent).to receive(:new)
        .and_wrap_original do |original, **kwargs|
          dev_instance = original.call(**kwargs)
          allow(dev_instance).to receive(:run) do |**run_kwargs|
            @dev_run_kwargs = run_kwargs
            {}
          end
          dev_instance
        end
    end

    it 'implements the requirements from agent-directed comments and posts replies' do
      with_github_pr(
        review_comments: [
          {
            databaseId: 666,
            createdAt: '2024-01-01T10:00:00Z',
            body: '/agent Please add a validation method',
            author: { login: 'reviewer1' },
            path: 'lib/foo.rb',
            replyTo: nil
          },
          {
            createdAt: '2024-01-01T11:00:00Z',
            body: 'This is a normal comment',
            author: { login: 'reviewer2' },
            path: 'lib/foo.rb',
            replyTo: nil
          }
        ]
      ) do
        run_cli 'review-comments', '42'
        expect(exit_status).to eq 0

        # Validate that we developed the right requirements
        expect(XAeonAgents::Agents::DeveloperAgent).to have_received(:new).with(hash_including(commit: true, pull_request: true))
        expect(dev_run_kwargs[:requirements]).to eq(
          'Add a new validation method. Devised from: "/agent Please add a validation method".'
        )

        # Validate that we answered all comments.
        expect(github_double).to have_received(:create_pull_request_comment_reply).with(
          'owner/repo',
          42,
          '[X-Aeon Agent ReviewResponder (Cline cline/stepfun/step-3.7-flash)] - ' \
            'Implemented the requested validation method. In response to: ' \
            '/agent Please add a validation method.',
          666
        )
      end
    end
  end
  # TODO: Add 1 test case validating the sessions usage: run the CLI with 1 session ID, then run it again with the same session ID, validate that Octokit was called again to retrieve the review comments, but DeveloperAgent and Octokit were not called again, then change the Octokit stub to return 1 more review comment, run again with the same session ID and validate that DeveloperAgent has been called with the new description of the issue, and that Octokit was called to post another reply.
  # TODO: Add 1 test case validating that the DeveloperAgent is not called if there are no requirements to be implemented, but still responses have been posted afterwards.
  # TODO: Add 1 test case validating that nothing gets triggered (neither DeveloperAgent nor replies) if there are no review comments.
  # TODO: Add 1 test case validating that nothing gets triggered (neither DeveloperAgent nor replies) if there are no review comments addressed to the agents (with `/agent` prefix).
  # TODO: Add 1 test case validating that only comments that have no replies yet from an agent are being replied to.
  # TODO: Add 1 test case validating that comments that are not addressed to the agent are not receiving responses.
  # TODO: Add 1 test case and the corresponding feature, making the PR number parameter optional on the CLI and retrieving automatically the right PR from Github corresponding at the current branch.
end
