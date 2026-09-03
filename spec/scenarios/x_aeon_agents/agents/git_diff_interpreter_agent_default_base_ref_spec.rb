describe XAeonAgents::Agents::GitDiffInterpreterAgent do
  before do
    stub_diff_agents
  end

  context 'with the default base ref (HEAD)' do
    it 'returns the expected artifacts when there are no differences' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        result = described_class.new(session_id: nil).run(git_ref_base: 'HEAD')
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
      end
    end

    it 'returns the one-line summary and change intent artifacts for diffs' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        File.write('test.txt', "modified content\n")
        result = described_class.new(session_id: nil).run(git_ref_base: 'HEAD')
        expect(normalize_git_ids(result[:one_line_summary])).to eq <<~EO_ARTIFACT.chomp
          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -original content +modified content ```  "
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
          -original content
          +modified content
          ```
        EO_ARTIFACT
      end
    end

    it 'interprets unstaged working-tree changes' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        File.write('test.txt', "unstaged modification\n")
        result = described_class.new(session_id: nil).run(git_ref_base: 'HEAD')
        expect(normalize_git_ids(result[:one_line_summary])).to eq <<~EO_ARTIFACT.chomp
          1-line summary of "Mocked change intent from the following diffs: ### New untracked files    ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -original content +unstaged modification ```  "
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
          -original content
          +unstaged modification
          ```
        EO_ARTIFACT
      end
    end

    it 'includes new untracked files in the diffs' do
      with_git_workspace(files: { 'test.txt' => "original content\n" }) do
        File.write('test.txt', "modified content\n")
        File.write('new_file.txt', "new untracked content\n")
        result = described_class.new(session_id: nil).run(git_ref_base: 'HEAD')
        expect(normalize_git_ids(result[:one_line_summary])).to eq <<~EO_ARTIFACT.chomp
          1-line summary of "Mocked change intent from the following diffs: ### New untracked files  #### new_file.txt ``` new untracked content  ```   ### git diff  ``` diff --git a/test.txt b/test.txt index git_short_hash..git_short_hash git_file_mode --- a/test.txt +++ b/test.txt @@ -1 +1 @@ -original content +modified content ```  "
        EO_ARTIFACT
        expect(normalize_git_ids(result[:change_intent].strip)).to eq <<~EO_ARTIFACT.chomp
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
        EO_ARTIFACT
      end
    end
  end
end
