describe XAeonAgents::Agents::PullRequestCreatorAgent do
  before do
    mock_github
    stub_git_diff_interpreter_agent
    stub_agent_run
  end

  describe 'authors credited in the Pull Request description' do
    it 'describes agent questions and ignores authors that have no conversation' do
      coder_agent = XAeonAgents::Agents::CoderAgent.new(session_id: nil)
      coder_agent.track_message(message: 'Add a new feature', author: 'user')
      coder_agent.track_message(message: 'Which file name should I use?', author: 'assistant', question: true)
      committer_agent = XAeonAgents::Agents::CommitterAgent.new(session_id: nil)

      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        branch: 'feature-branch',
        remotes: { 'origin' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        described_class.new(session_id: nil, authors: [coder_agent, committer_agent]).run(pr_base_ref: 'main')

        expect(github_double).to have_received(:create_pull_request).with(
          'owner/repo',
          'main',
          'feature-branch',
          'Mocked 1-line summary of changes from base main',
          an_object_satisfying { |description|
            description.include?('› **assistant**') &&
              description.include?('Which file name should I use?') &&
              description.include?('- Coder (Cline cline/anthropic/claude-sonnet-4.6)') &&
              description.include?('- Committer (CommitterAgent)')
          }
        )
      end
    end
  end
end
