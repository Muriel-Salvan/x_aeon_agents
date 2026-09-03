describe XAeonAgents::Agents::GitDiffInterpreterAgent do
  before do
    stub_diff_agents
  end

  # TODO: Don't use this method anymore: expectations should be written on the resulting output artifacts in the test scenarios directly. No need to convert to String output.
  def run_interpret_diffs(base_ref = 'HEAD', session_id: nil)
    result = described_class.new(session_id: session_id).run(git_ref_base: base_ref)
    <<~EO_OUTPUT
      ===== Code diffs interpretation:

      #{result[:one_line_summary].strip}

      #{result[:change_intent].strip}
    EO_OUTPUT
  end

  context 'with a custom session id' do
    it 'reuses previous steps when a session id is used' do
      with_git_workspace(files: { 'test.txt' => "Test content\n" }) do
        run_interpret_diffs(session_id: 'test-session-123')
        stub_diff_agents(change_intent_message: 'Another change intent from the following diffs')
        output = run_interpret_diffs(session_id: 'test-session-123')
        expect(normalize_git_ids(output)).to include <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ```  ```  "

          Mocked change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```

          ```
        EO_STDOUT
        output = run_interpret_diffs(session_id: 'test-session-456')
        expect(normalize_git_ids(output)).to include <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Another change intent from the following diffs: ### New untracked files    ### git diff  ```  ```  "

          Another change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```

          ```
        EO_STDOUT
      end
    end
  end
end
