describe XAeonAgents::Cli, '#interpret_diffs' do
  before do
    stub_diff_agents
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
end
