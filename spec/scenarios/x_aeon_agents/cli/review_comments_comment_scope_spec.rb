describe XAeonAgents::Cli, '#review_comments' do
  before do
    stub_review_resolver_agent
    stub_developer_agent
  end

  context 'with no review comments' do
    it 'triggers neither DeveloperAgent nor replies' do
      with_github_pr(review_comments: []) do
        run_cli 'review-comments', '42'
        expect(exit_status).to eq 0

        expect(find_run_calls_for(XAeonAgents::Agents::FeedbackAnalystAgent)).to be_nil
        expect(XAeonAgents::Agents::DeveloperAgent).not_to have_received(:new)
        expect(github_double).not_to have_received(:create_pull_request_comment_reply)
      end
    end
  end

  context 'with no review comments addressed to the agents' do
    it 'triggers neither DeveloperAgent nor replies' do
      with_github_pr(
        review_comments: [
          {
            databaseId: 200,
            createdAt: '2024-01-01T10:00:00Z',
            body: 'This is a normal comment',
            author: { login: 'reviewer2' },
            path: 'lib/foo.rb',
            replyTo: nil
          },
          {
            databaseId: 201,
            createdAt: '2024-01-01T11:00:00Z',
            body: 'Another unrelated comment',
            author: { login: 'reviewer3' },
            path: 'lib/foo.rb',
            replyTo: nil
          }
        ]
      ) do
        run_cli 'review-comments', '42'
        expect(exit_status).to eq 0

        expect(find_run_calls_for(XAeonAgents::Agents::FeedbackAnalystAgent)).to be_nil
        expect(XAeonAgents::Agents::DeveloperAgent).not_to have_received(:new)
        expect(github_double).not_to have_received(:create_pull_request_comment_reply)
      end
    end
  end

  context 'with already replied comments' do
    it 'only replies to comments that have no agent reply yet' do
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
            databaseId: 667,
            createdAt: '2024-01-01T10:30:00Z',
            body: '[X-Aeon Agent (Cline cline/stepfun/step-3.7-flash)] - Already replied',
            author: { login: 'x-aeon-agent' },
            path: 'lib/foo.rb',
            replyTo: { databaseId: 666 }
          },
          {
            databaseId: 668,
            createdAt: '2024-01-02T10:00:00Z',
            body: '/agent Please add another method',
            author: { login: 'reviewer1' },
            path: 'lib/foo.rb',
            replyTo: nil
          }
        ]
      ) do
        run_cli 'review-comments', '42'
        expect(exit_status).to eq 0

        # Only the unreplied agent-directed comment (668) is in scope; 666 already has an agent reply.

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
              'need_ai_reply' => false,
              'path' => 'lib/foo.rb',
              'reply_to_comment_id' => nil
            },
            {
              'author' => 'x-aeon-agent',
              'body' => '[X-Aeon Agent (Cline cline/stepfun/step-3.7-flash)] - Already replied',
              'comment_id' => 667,
              'created_at' => '2024-01-01T10:30:00Z',
              'need_ai_reply' => false,
              'path' => 'lib/foo.rb',
              'reply_to_comment_id' => 666
            },
            {
              'author' => 'reviewer1',
              'body' => '/agent Please add another method',
              'comment_id' => 668,
              'created_at' => '2024-01-02T10:00:00Z',
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
            'created_at' => '2024-01-02T10:00:00Z',
            'need_ai_reply' => true,
            'path' => 'lib/foo.rb',
            'reply_to_comment_id' => nil
          }
        ]

        # Only the unreplied comment (668) gets a new reply; 666 already has an agent reply.
        expect(github_double).to have_received(:create_pull_request_comment_reply).with(
          'owner/repo',
          42,
          '[X-Aeon Agent ReviewResponder (Cline cline/stepfun/step-3.7-flash)] - ' \
            'Implemented the requested validation method. In response to: ' \
            '/agent Please add another method.',
          668
        )
        expect(github_double).not_to have_received(:create_pull_request_comment_reply).with('owner/repo', 42, anything, 666)
      end
    end
  end
end
