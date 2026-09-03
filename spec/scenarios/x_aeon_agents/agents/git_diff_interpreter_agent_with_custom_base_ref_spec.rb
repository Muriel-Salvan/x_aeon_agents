describe XAeonAgents::Agents::GitDiffInterpreterAgent do
  before do
    stub_diff_agents
  end

  context 'with a custom base ref' do
    it 'supports a relative ref such as HEAD~1' do
      with_git_workspace(files: { 'test.txt' => "version 1\n" }) do
        git_base = Git.open(Dir.pwd)
        File.write('test.txt', "version 2\n")
        git_base.add('test.txt')
        git_base.commit('Second commit')
        File.write('test.txt', "version 3\n")
        result = described_class.new(session_id: nil).run(git_ref_base: 'HEAD~1')
        expect(normalize_git_ids(result[:one_line_summary])).to eq <<~EO_ARTIFACT.chomp
          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -version 1 +version 3 ```  "
        EO_ARTIFACT
        expect(normalize_git_ids(result[:change_intent].strip)).to eq <<~EO_ARTIFACT.chomp
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
        EO_ARTIFACT
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
        result = described_class.new(session_id: nil).run(git_ref_base: 'feature-branch')
        expect(normalize_git_ids(result[:one_line_summary])).to eq <<~EO_ARTIFACT.chomp
          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -version 1 +version 3 ```  "
        EO_ARTIFACT
        expect(normalize_git_ids(result[:change_intent].strip)).to eq <<~EO_ARTIFACT.chomp
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
        EO_ARTIFACT
      end
    end

    it 'uses the :cached base ref to only show staged diffs' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        File.write('test.txt', "staged modification\n")
        # TODO: Use the Git library
        `git add test.txt`
        File.write('test.txt', "unstaged change\n")
        result = described_class.new(session_id: nil).run(git_ref_base: 'cached')
        expect(normalize_git_ids(result[:one_line_summary])).to eq <<~EO_ARTIFACT.chomp
          1-line summary of "Mocked change intent from the following diffs: ### git diff --cached  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -original content +staged modification ```  "
        EO_ARTIFACT
        expect(normalize_git_ids(result[:change_intent].strip)).to eq <<~EO_ARTIFACT.chomp
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
        EO_ARTIFACT
      end
    end
  end
end
