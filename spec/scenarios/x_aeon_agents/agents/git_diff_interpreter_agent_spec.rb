require_relative 'shared_examples/common_behavior'

describe XAeonAgents::Agents::GitDiffInterpreterAgent do
  before do
    stub_diff_agents
  end

  it_behaves_like 'an agent with common behavior', described_class

  describe 'user instructions given to its sub-agents' do
    it 'instructs the diff interpreter agent to analyze the diffs' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        described_class.new(session_id: nil).run(git_ref_base: 'HEAD')
        expect(find_run_calls_for(XAeonAgents::Agents::DiffInterpreterAgent)[:kwargs][:user_instructions])
          .to eq 'Analyze the diffs given'
      end
    end

    it 'instructs the 1-line code diff summarizer agent to summarize the change intent' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        described_class.new(session_id: nil).run(git_ref_base: 'HEAD')
        expect(find_run_calls_for(XAeonAgents::Agents::OneLineCodeDiffSummarizerAgent)[:kwargs][:user_instructions])
          .to eq 'Summarize the diffs given in 1 line'
      end
    end
  end
end
