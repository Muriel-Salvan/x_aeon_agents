describe XAeonAgents::Cli, '#review_comments' do
  before do
    stub_review_resolver_agent
    stub_developer_agent
  end

  context 'when there are agent-directed review comments' do
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
            },
            {
              'author' => 'reviewer2',
              'body' => 'This is a normal comment',
              'comment_id' => 101,
              'created_at' => '2024-01-01T11:00:00Z',
              'need_ai_reply' => nil,
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

        # Validate that we developed the right requirements
        expect(XAeonAgents::Agents::DeveloperAgent).to have_received(:new).with(hash_including(commit: true, pull_request: true))
        expect(developer_agent_run_calls.last[:kwargs][:requirements]).to eq(
          'Add a new validation method. Devised from: "/agent Please add a validation method".'
        )

        # Validate that we answered all comments.
        expect(github_double).to have_received(:create_pull_request_comment_reply).with(
          'owner/repo',
          42,
          '[X-Aeon Agent ReviewResponder (Cline cline/test-free-complex-planning-model)] - ' \
            'Implemented the requested validation method. In response to: ' \
            '/agent Please add a validation method.',
          666
        )
      end
    end

    context 'with no requirements to implement' do
      it 'posts replies but does not call the DeveloperAgent' do
        with_github_pr(
          review_comments: [
            {
              databaseId: 666,
              createdAt: '2024-01-01T10:00:00Z',
              body: '/agent What do you think about the naming?',
              author: { login: 'reviewer1' },
              path: 'lib/foo.rb',
              replyTo: nil
            }
          ]
        ) do
          # Override the FeedbackAnalystAgent stub to return "No requirements"
          stub_agent_run(
            stub_handler: lambda { |agent, **kwargs|
              case agent
              when XAeonAgents::Agents::FeedbackAnalystAgent
                { requirements: 'No requirements' }
              when XAeonAgents::Agents::ReviewResponderAgent
                { reply: "I think the naming is fine as is. In response to: #{kwargs[:open_comment_for_reply]['body']}." }
              else
                {}
              end
            }
          )

          run_cli 'review-comments', '42'
          expect(exit_status).to eq 0

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
                'body' => '/agent What do you think about the naming?',
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
              'body' => '/agent What do you think about the naming?',
              'comment_id' => 666,
              'created_at' => '2024-01-01T10:00:00Z',
              'need_ai_reply' => true,
              'path' => 'lib/foo.rb',
              'reply_to_comment_id' => nil
            }
          ]
          expect(XAeonAgents::Agents::DeveloperAgent).not_to have_received(:new)
          expect(github_double).to have_received(:create_pull_request_comment_reply).with(
            'owner/repo',
            42,
            '[X-Aeon Agent ReviewResponder (Cline cline/test-free-complex-planning-model)] - ' \
              'I think the naming is fine as is. In response to: ' \
              '/agent What do you think about the naming?.',
            666
          )
        end
      end
    end
  end
end
