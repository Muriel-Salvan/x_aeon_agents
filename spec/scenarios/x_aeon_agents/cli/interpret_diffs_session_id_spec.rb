describe XAeonAgents::Cli, '#interpret_diffs' do
  before do
    stub_diff_agents
  end

  context 'with a custom session id' do
    it 'reuses previous steps when a session id is used' do
      with_git_workspace(files: { 'test.txt' => "Test content\n" }) do
        run_cli 'interpret-diffs', '--session-id', 'test-session-123'
        stub_diff_agents(change_intent_message: 'Another change intent from the following diffs')
        run_cli 'interpret-diffs', '--session-id', 'test-session-123'
        expect_stdout <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ```  ```  "

          Mocked change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```

          ```
        EO_STDOUT
        run_cli 'interpret-diffs', '--session-id', 'test-session-456'
        expect_stdout <<~EO_STDOUT
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
