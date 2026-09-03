describe XAeonAgents::Agents::GitDiffInterpreterAgent do
  before do
    stub_diff_agents
  end

  context 'with a custom session id' do
    it 'reuses previous steps when a session id is used' do
      with_git_workspace(files: { 'test.txt' => "Test content\n" }) do
        described_class.new(session_id: 'test-session-123').run(git_ref_base: 'HEAD')
        stub_diff_agents(change_intent_message: 'Another change intent from the following diffs')
        result = described_class.new(session_id: 'test-session-123').run(git_ref_base: 'HEAD')
        expect(normalize_git_ids(result[:one_line_summary])).to eq <<~EO_ARTIFACT.chomp
          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ```  ```  "
        EO_ARTIFACT
        expect(normalize_git_ids(result[:change_intent].strip)).to eq <<~EO_ARTIFACT.chomp
          Mocked change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```

          ```
        EO_ARTIFACT
        result = described_class.new(session_id: 'test-session-456').run(git_ref_base: 'HEAD')
        expect(normalize_git_ids(result[:one_line_summary])).to eq <<~EO_ARTIFACT.chomp
          1-line summary of "Another change intent from the following diffs: ### New untracked files    ### git diff  ```  ```  "
        EO_ARTIFACT
        expect(normalize_git_ids(result[:change_intent].strip)).to eq <<~EO_ARTIFACT.chomp
          Another change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```

          ```
        EO_ARTIFACT
      end
    end
  end
end
