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

  context 'with a custom base ref' do
    it 'supports a relative ref such as HEAD~1' do
      with_git_workspace(files: { 'test.txt' => "version 1\n" }) do
        git_base = Git.open(Dir.pwd)
        File.write('test.txt', "version 2\n")
        git_base.add('test.txt')
        git_base.commit('Second commit')
        File.write('test.txt', "version 3\n")
        output = run_interpret_diffs('HEAD~1')
        expect(normalize_git_ids(output)).to include <<~EO_STDOUT
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
        `git branch feature-branch`
        git_base = Git.open(Dir.pwd)
        File.write('test.txt', "version 2\n")
        git_base.add('test.txt')
        git_base.commit('Second commit')
        File.write('test.txt', "version 3\n")
        output = run_interpret_diffs('feature-branch')
        expect(normalize_git_ids(output)).to include <<~EO_STDOUT
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
        File.write('test.txt', "staged modification\n")
        # TODO: Use the Git library
        `git add test.txt`
        File.write('test.txt', "unstaged change\n")
        output = run_interpret_diffs('cached')
        expect(normalize_git_ids(output)).to include <<~EO_STDOUT
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
