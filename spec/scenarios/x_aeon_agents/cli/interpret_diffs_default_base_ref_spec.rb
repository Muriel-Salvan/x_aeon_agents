describe XAeonAgents::Cli, '#interpret_diffs' do
  before do
    stub_diff_agents
  end

  context 'with the default base ref (HEAD)' do
    it 'prints the expected messages when there are no differences' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        # No modifications: working tree matches HEAD exactly
        run_cli 'interpret-diffs'
        expect_stdout <<~EO_STDOUT
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
        run_cli 'interpret-diffs'
        expect_stdout <<~EO_STDOUT
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
        run_cli 'interpret-diffs'
        diff_call = agent_run_calls.find { |c| c[:kwargs].key?(:files_diff) }
        expect(diff_call[:kwargs][:files_diff]).to include('unstaged modification')
        expect_stdout <<~EO_STDOUT
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
        run_cli 'interpret-diffs'
        expect_stdout <<~EO_STDOUT
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
