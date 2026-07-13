describe XAeonAgents::Cli, '#review_comments' do
  before do
    stub_review_resolver_agent
    stub_developer_agent
  end

  context 'with sessions' do
    let(:comments) do
      [
        {
          databaseId: 666,
          createdAt: '2024-01-01T10:00:00Z',
          body: '/agent Please add a validation method',
          author: { login: 'reviewer1' },
          path: 'lib/foo.rb',
          replyTo: nil
        }
      ]
    end

    it 'caches development and replies but re-fetches comments and processes new ones' do
      with_github_pr(review_comments: comments) do
        git = Git.open(Dir.pwd)
        base_sha = git.rev_parse('HEAD~1')
        head_sha = git.rev_parse('HEAD')

        # First run with a fixed session ID
        run_cli 'review-comments', '42', '--session-id', 'session-1'
        expect(exit_status).to eq 0

        expect(github_double).to have_received(:post).with('/graphql', a_string_including('"pr":42')).once

        # Validate that FeedbackAnalystAgent received the right input artifacts
        feedback_inputs = find_run_calls_for(XAeonAgents::Agents::FeedbackAnalystAgent)[:kwargs]
        expect(feedback_inputs[:pr_description]).to eq "# My Pull Request\n\nPR body description"
        expect(normalize_git_ids(feedback_inputs[:pr_files_diffs])).to eq <<~EO_DIFF.chomp
          diff --git a/test.txt b/test.txt
          index git_short_hash..git_short_hash git_file_mode
          --- a/test.txt
          +++ b/test.txt
          @@ -1 +1 @@
          -original
          +modified
        EO_DIFF
        expect(feedback_inputs[:conversations]).to eq [
          [
            {
              'author' => 'reviewer1',
              'body' => '/agent Please add a validation method',
              'comment_id' => 666,
              'created_at' => '2024-01-01T10:00:00Z',
              'need_ai_reply' => true,
              'path' => 'lib/foo.rb',
              'reply_to_comment_id' => nil
            }
          ]
        ]
        expect(feedback_inputs[:open_comments_to_agents]).to eq [
          {
            'author' => 'reviewer1',
            'body' => '/agent Please add a validation method',
            'comment_id' => 666,
            'created_at' => '2024-01-01T10:00:00Z',
            'need_ai_reply' => true,
            'path' => 'lib/foo.rb',
            'reply_to_comment_id' => nil
          }
        ]

        expect(developer_agent_run_calls.size).to eq 1
        expect(developer_agent_run_calls.last[:kwargs][:requirements]).to eq(
          'Add a new validation method. Devised from: ' \
            '"/agent Please add a validation method".'
        )
        expect(github_double).to have_received(:create_pull_request_comment_reply).once
        expect(github_double).to have_received(:create_pull_request_comment_reply).with(
          'owner/repo',
          42,
          '[X-Aeon Agent ReviewResponder (Cline cline/stepfun/step-3.7-flash)] - ' \
            'Implemented the requested validation method. In response to: ' \
            '/agent Please add a validation method.',
          666
        )

        # Mock the reply
        comment_reply = {
          databaseId: 667,
          createdAt: '2024-01-02T10:01:00Z',
          body: '[X-Aeon Agent ReviewResponder (Cline cline/stepfun/step-3.7-flash)] - ' \
            'Implemented the requested validation method. In response to: ' \
            '/agent Please add a validation method.',
          author: { login: 'assistant' },
          path: 'lib/foo.rb',
          replyTo: { databaseId: 666 }
        }
        mock_pull_request(
          ref: 'feature-branch',
          base_sha:,
          head_sha:,
          review_comments: comments + [comment_reply]
        )

        # Second run with the same session ID: Octokit (graphql) is called again to re-fetch comments,
        # the reply should be fetched, but no other comment requires the attention of our agent.
        run_cli 'review-comments', '42', '--session-id', 'session-1'
        expect(exit_status).to eq 0

        expect(github_double).to have_received(:post).with('/graphql', a_string_including('"pr":42')).twice
        expect(developer_agent_run_calls.size).to eq 1
        expect(github_double).to have_received(:create_pull_request_comment_reply).once

        # Add a new review comment and re-stub the graphql response.
        mock_pull_request(
          ref: 'feature-branch',
          base_sha:,
          head_sha:,
          review_comments: comments + [
            comment_reply,
            {
              databaseId: 668,
              createdAt: '2024-01-02T10:02:00Z',
              body: '/agent Please add another method',
              author: { login: 'reviewer1' },
              path: 'lib/foo.rb',
              replyTo: nil
            }
          ]
        )

        # Third run with the same session ID: the new comment is detected (comments re-fetched),
        # DeveloperAgent runs again with the new comment, and a new reply is posted.
        run_cli 'review-comments', '42', '--session-id', 'session-1'
        expect(exit_status).to eq 0

        expect(github_double).to have_received(:post).with('/graphql', a_string_including('"pr":42')).exactly(3).times
        expect(developer_agent_run_calls.size).to eq 2
        # The 3rd run re-ran the FeedbackAnalystAgent with both agent-directed comments (old + new).
        feedback_calls = find_run_calls_for(XAeonAgents::Agents::FeedbackAnalystAgent, all: true)
        expect(feedback_calls.size).to eq 2
        feedback_inputs = feedback_calls.last[:kwargs]
        expect(feedback_inputs[:pr_description]).to eq "# My Pull Request\n\nPR body description"
        expect(normalize_git_ids(feedback_inputs[:pr_files_diffs])).to eq <<~EO_DIFF.chomp
          diff --git a/test.txt b/test.txt
          index git_short_hash..git_short_hash git_file_mode
          --- a/test.txt
          +++ b/test.txt
          @@ -1 +1 @@
          -original
          +modified
        EO_DIFF
        expect(feedback_inputs[:conversations]).to eq [
          [
            {
              'author' => 'reviewer1',
              'body' => '/agent Please add a validation method',
              'comment_id' => 666,
              'created_at' => '2024-01-01T10:00:00Z',
              'need_ai_reply' => false,
              'path' => 'lib/foo.rb',
              'reply_to_comment_id' => nil
            },
            {
              'author' => 'assistant',
              'body' => '[X-Aeon Agent ReviewResponder (Cline cline/stepfun/step-3.7-flash)] - ' \
                'Implemented the requested validation method. In response to: ' \
                '/agent Please add a validation method.',
              'comment_id' => 667,
              'created_at' => '2024-01-02T10:01:00Z',
              'need_ai_reply' => false,
              'path' => 'lib/foo.rb',
              'reply_to_comment_id' => 666
            },
            {
              'author' => 'reviewer1',
              'body' => '/agent Please add another method',
              'comment_id' => 668,
              'created_at' => '2024-01-02T10:02:00Z',
              'need_ai_reply' => true,
              'path' => 'lib/foo.rb',
              'reply_to_comment_id' => nil
            }
          ]
        ]
        expect(feedback_inputs[:open_comments_to_agents]).to eq [
          {
            'author' => 'reviewer1',
            'body' => '/agent Please add another method',
            'comment_id' => 668,
            'created_at' => '2024-01-02T10:02:00Z',
            'need_ai_reply' => true,
            'path' => 'lib/foo.rb',
            'reply_to_comment_id' => nil
          }
        ]
        expect(developer_agent_run_calls.last[:kwargs][:requirements]).to eq(
          'Add a new validation method. Devised from: ' \
            '"/agent Please add another method".'
        )
        expect(github_double).to have_received(:create_pull_request_comment_reply).twice
        expect(github_double).to have_received(:create_pull_request_comment_reply).with(
          'owner/repo',
          42,
          '[X-Aeon Agent ReviewResponder (Cline cline/stepfun/step-3.7-flash)] - ' \
            'Implemented the requested validation method. In response to: ' \
            '/agent Please add another method.',
          668
        )
      end
    end
  end
end
