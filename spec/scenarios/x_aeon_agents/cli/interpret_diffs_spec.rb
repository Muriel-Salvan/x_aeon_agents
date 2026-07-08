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

  context 'with a custom base ref' do
    it 'supports a relative ref such as HEAD~1' do
      with_git_workspace(files: { 'test.txt' => "version 1\n" }) do
        git_base = Git.open(Dir.pwd)
        # Commit a second version so HEAD~1 differs from HEAD
        File.write('test.txt', "version 2\n")
        git_base.add('test.txt')
        git_base.commit('Second commit')
        # Modify the file without committing: diff from HEAD~1 includes both
        # the second commit and the working-tree change
        File.write('test.txt', "version 3\n")
        run_cli 'interpret-diffs', 'HEAD~1'
        # The files_diff agent should receive content spanning from HEAD~1
        expect_stdout <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -version 1 +version 3 ```  "

          Mocked change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```
          diff --git a/test.txt b/test.txt
          index git_short_hash..git_short_hash git_file_mode
          --- a/test.txt
          +++ b/test.txt
          @@ -1 +1 @@
          -version 1
          +version 3
          ```
        EO_STDOUT
      end
    end

    it 'supports a branch name as base ref' do
      with_git_workspace(files: { 'test.txt' => "version 1\n" }) do
        # Create a branch at the initial commit
        `git branch feature-branch`
        git_base = Git.open(Dir.pwd)
        # Commit a change on the current branch (main)
        File.write('test.txt', "version 2\n")
        git_base.add('test.txt')
        git_base.commit('Second commit')
        File.write('test.txt', "version 3\n")
        run_cli 'interpret-diffs', 'feature-branch'
        expect_stdout <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -version 1 +version 3 ```  "

          Mocked change intent from the following diffs:
          ### New untracked files



          ### git diff

          ```
          diff --git a/test.txt b/test.txt
          index git_short_hash..git_short_hash git_file_mode
          --- a/test.txt
          +++ b/test.txt
          @@ -1 +1 @@
          -version 1
          +version 3
          ```
        EO_STDOUT
      end
    end

    it 'uses the :cached base ref to only show staged diffs' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        # Stage a modification
        File.write('test.txt', "staged modification\n")
        # TODO: Use the Git library
        `git add test.txt`
        # Make a non-staged modification
        File.write('test.txt', "unstaged change\n")
        run_cli 'interpret-diffs', 'cached'
        # Verify staged diff is present and non-staged changes are excluded
        expect_stdout <<~EO_STDOUT
          ===== Code diffs interpretation:

          1-line summary of "Mocked change intent from the following diffs: ### git diff --cached  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -original content +staged modification ```  "

          Mocked change intent from the following diffs:
          ### git diff --cached

          ```
          diff --git a/test.txt b/test.txt
          index git_short_hash..git_short_hash git_file_mode
          --- a/test.txt
          +++ b/test.txt
          @@ -1 +1 @@
          -original content
          +staged modification
          ```
        EO_STDOUT
      end
    end
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
