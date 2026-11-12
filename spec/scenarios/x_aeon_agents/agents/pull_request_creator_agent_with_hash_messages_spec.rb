describe XAeonAgents::Agents::PullRequestCreatorAgent do
  before do
    mock_github
    stub_git_diff_interpreter_agent
    stub_agent_run
  end

  describe 'authors with non-String conversation messages' do
    it 'does not crash on Hash (Cline ask_question) messages and includes the question text' do
      planner_agent = XAeonAgents::Agents::CoderAgent.new(session_id: nil)
      planner_agent.track_message(message: 'Initial task instructions', author: 'user')
      fake_question = Struct.new(:payload) do
        def to_hash = payload
      end.new({ question: 'Confirm understanding?', options: %w[yes no] })
      planner_agent.track_message(message: fake_question, author: 'assistant', question: true)
      planner_agent.track_message(message: 'Yes, proceed', author: 'user')

      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        described_class.new(session_id: nil, authors: [planner_agent]).run(pr_base_ref: 'main')

        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          an_object_satisfying { |description|
            description.include?('Confirm understanding?') &&
              description.include?('Yes, proceed')
          }
        )
      end
    end

    it 'renders Hash messages with String keys (Shale to_hash variance)' do
      planner_agent = XAeonAgents::Agents::CoderAgent.new(session_id: nil)
      planner_agent.track_message(message: 'Initial task instructions', author: 'user')
      fake_question = Struct.new(:payload) do
        def to_hash = payload
      end.new({ 'text' => 'Should I continue?' })
      planner_agent.track_message(message: fake_question, author: 'assistant', question: true)
      planner_agent.track_message(message: 'Go ahead', author: 'user')

      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        described_class.new(session_id: nil, authors: [planner_agent]).run(pr_base_ref: 'main')

        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          an_object_satisfying { |description|
            description.include?('Should I continue?') &&
              description.include?('Go ahead')
          }
        )
      end
    end

    it 'skips nil and empty messages without crashing' do
      coder_agent = XAeonAgents::Agents::CoderAgent.new(session_id: nil)
      coder_agent.track_message(message: 'Add a new feature', author: 'user')
      coder_agent.track_message(message: nil, author: 'assistant')
      coder_agent.track_message(message: '   ', author: 'assistant')
      coder_agent.track_message(message: 'Real feedback', author: 'user')

      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        described_class.new(session_id: nil, authors: [coder_agent]).run(pr_base_ref: 'main')

        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          an_object_satisfying { |description|
            description.include?('Real feedback')
          }
        )
      end
    end

    it 'does not mutate the authors live conversation' do
      coder_agent = XAeonAgents::Agents::CoderAgent.new(session_id: nil)
      coder_agent.track_message(message: 'Which file name should I use?', author: 'assistant', question: true)
      coder_agent.track_message(message: 'file.rb', author: 'user')
      conversation_size_before = coder_agent.conversation.size

      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        described_class.new(session_id: nil, authors: [coder_agent]).run(pr_base_ref: 'main')

        expect(coder_agent.conversation.size).to eq conversation_size_before
        expect(github_double).to have_received(:create_pull_request)
      end
    end

    it 'falls back to to_s for non-String/Hash/nil messages' do
      coder_agent = XAeonAgents::Agents::CoderAgent.new(session_id: nil)
      allow(coder_agent).to receive(:conversation).and_return(
        [
          { at: Time.now.utc, author: 'assistant', message: 'Initial instructions' },
          { at: Time.now.utc, author: 'user', message: 12_345 }
        ]
      )

      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        described_class.new(session_id: nil, authors: [coder_agent]).run(pr_base_ref: 'main')

        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          an_object_satisfying { |description| description.include?('12345') }
        )
      end
    end
  end
end
