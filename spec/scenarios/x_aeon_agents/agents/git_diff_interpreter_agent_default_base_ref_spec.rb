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

  context 'with the default base ref (HEAD)' do
    it 'prints the expected messages when there are no differences' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        output = run_interpret_diffs
        expect(normalize_git_ids(output)).to include <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ```  ```  "

          Mocked change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```

          ```
        EO_STDOUT
      end
    end

    it 'prints the interpretation header, one-line summary and change intent for diffs' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        File.write('test.txt', "modified content\n")
        output = run_interpret_diffs
        expect(normalize_git_ids(output)).to include <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -original content +modified content ```  "

          Mocked change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```
          diff --git a/test.txt b/test.txt
          index git_short_hash..git_short_hash git_file_mode
          --- a/test.txt
          +++ b/test.txt
          @@ -1 +1 @@
          -original content
          +modified content
          ```
        EO_STDOUT
      end
    end

    it 'interprets unstaged working-tree changes' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        File.write('test.txt', "unstaged modification\n")
        output = run_interpret_diffs
        expect(normalize_git_ids(output)).to include <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -original content +unstaged modification ```  "

          Mocked change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```
          diff --git a/test.txt b/test.txt
          index git_short_hash..git_short_hash git_file_mode
          --- a/test.txt
          +++ b/test.txt
          @@ -1 +1 @@
          -original content
          +unstaged modification
          ```
        EO_STDOUT
      end
    end

    it 'includes new untracked files in the diffs' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        File.write('test.txt', "modified content\n")
        File.write('new_file.txt', "new untracked content\n")
        output = run_interpret_diffs
        expect(normalize_git_ids(output)).to include <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Mocked change intent from the following diffs: ### New untracked files  #### new_file.txt ``` new untracked content  ```   ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -original content +modified content ```  "

          Mocked change intent from the following diffs:
          ### New untracked files

          #### new_file.txt
          ```
          new untracked content

          ```


          ### git diff

          ```
          diff --git a/test.txt b/test.txt
          index git_short_hash..git_short_hash git_file_mode
          --- a/test.txt
          +++ b/test.txt
          @@ -1 +1 @@
          -original content
          +modified content
          ```
        EO_STDOUT
      end
    end
  end
end
