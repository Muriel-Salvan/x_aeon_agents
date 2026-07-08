require 'git'

describe XAeonAgents::Cli, '#commit' do
  before do
    # Stub GitDiffInterpreterAgent to avoid AI calls.
    # The run method outputs the 2 needed artifacts (one_line_summary, change_intent)
    # using the content of the input artifacts (the actual git cached diff).
    agent = instance_double(XAeonAgents::Agents::GitDiffInterpreterAgent)
    allow(agent).to receive(:run) do |git_ref_base:|
      {
        one_line_summary: "1-line summary of diff from #{git_ref_base}",
        change_intent: "Change intent of the diff from #{git_ref_base}"
      }
    end
    allow(agent).to receive(:diff_interpreter_agent) do
      instance_double(XAeonAgents::Agents::DiffInterpreterAgent, full_name: 'Test Agent')
    end
    allow(XAeonAgents::Agents::GitDiffInterpreterAgent).to receive(:new)
      .and_return(agent)
    # Stub Launchy.open and $stdin.gets to avoid interactive prompts during tests
    stub_review_content
  end

  context 'when there are no changes' do
    it 'does not create a commit' do
      with_git_workspace(files: { 'test.txt' => "content\n" }) do
        run_cli 'commit'
        expect(Git.open(Dir.pwd).log.execute.count).to eq(1) # Only the initial commit
      end
    end
  end

  context 'when changes are staged' do
    it 'creates a commit with the staged changes' do
      with_git_workspace(files: { 'test.txt' => "original\n" }) do
        File.write('test.txt', "modified\n")
        # TODO: Use the Git library
        `git add test.txt`
        run_cli 'commit'
        git_log = Git.open(Dir.pwd).log.execute
        expect(git_log.count).to eq(2)
        expect_commit(
          git_log.first,
          <<~EO_COMMIT,
            1-line summary of diff from cached

            Change intent of the diff from cached

            Co-authored by X-Aeon AI Agents:
            * Test Agent
          EO_COMMIT
          <<~EO_PATCH
            diff --git a/test.txt b/test.txt
            index git_short_hash..git_short_hash git_file_mode
            --- a/test.txt
            +++ b/test.txt
            @@ -1 +1 @@
            -original
            +modified
          EO_PATCH
        )
        # Validate the file to be reviewed had the right content
        expect(opened_review_files.size).to eq(1)
        expect(normalize_git_ids(reviewed_content)).to eq <<~EO_REVIEW
          1-line summary of diff from cached

          Change intent of the diff from cached

          Co-authored by X-Aeon AI Agents:
          * Test Agent
        EO_REVIEW
      end
    end

    it 'uses the content after user modifications to the review file' do
      with_git_workspace(files: { 'test.txt' => "original\n" }) do
        File.write('test.txt', "modified\n")
        `git add test.txt`
        stub_review_content do |file_path|
          # Simulate user editing the review file before pressing Enter
          File.write(file_path, "Custom commit message\n\nEdited by user\n\n#{File.read(file_path)}")
        end
        run_cli 'commit'
        git_log = Git.open(Dir.pwd).log.execute
        expect(git_log.count).to eq(2)
        expect_commit(
          git_log.first,
          <<~EO_COMMIT,
            Custom commit message

            Edited by user

            1-line summary of diff from cached

            Change intent of the diff from cached

            Co-authored by X-Aeon AI Agents:
            * Test Agent
          EO_COMMIT
          <<~EO_PATCH
            diff --git a/test.txt b/test.txt
            index git_short_hash..git_short_hash git_file_mode
            --- a/test.txt
            +++ b/test.txt
            @@ -1 +1 @@
            -original
            +modified
          EO_PATCH
        )
      end
    end
  end

  context 'when changes are not staged' do
    it 'stages all files and creates a commit' do
      with_git_workspace(files: { 'test.txt' => "original\n" }) do
        File.write('test.txt', "modified\n")
        run_cli 'commit'
        git_log = Git.open(Dir.pwd).log.execute
        expect(git_log.count).to eq(2)
        expect_commit(
          git_log.first,
          <<~EO_COMMIT,
            1-line summary of diff from cached

            Change intent of the diff from cached

            Co-authored by X-Aeon AI Agents:
            * Test Agent
          EO_COMMIT
          <<~EO_PATCH
            diff --git a/test.txt b/test.txt
            index git_short_hash..git_short_hash git_file_mode
            --- a/test.txt
            +++ b/test.txt
            @@ -1 +1 @@
            -original
            +modified
          EO_PATCH
        )
        # Validate Launchy was called on a file containing expected content
        expect(opened_review_files.size).to eq(1)
        expect(normalize_git_ids(reviewed_content)).to eq <<~EO_REVIEW
          1-line summary of diff from cached

          Change intent of the diff from cached

          Co-authored by X-Aeon AI Agents:
          * Test Agent
        EO_REVIEW
      end
    end
  end

  context 'when part of changes are staged and others not' do
    it 'commits only the staged changes' do
      with_git_workspace(files: { 'file1.txt' => "original1\n", 'file2.txt' => "original2\n" }) do
        File.write('file1.txt', "modified1\n")
        File.write('file2.txt', "modified2\n")
        `git add file1.txt`
        run_cli 'commit'
        git_log = Git.open(Dir.pwd).log.execute
        expect(git_log.count).to eq(2)
        # The commit should only contain file1.txt (staged)
        expect_commit(
          git_log.first,
          <<~EO_COMMIT,
            1-line summary of diff from cached

            Change intent of the diff from cached

            Co-authored by X-Aeon AI Agents:
            * Test Agent
          EO_COMMIT
          <<~EO_PATCH
            diff --git a/file1.txt b/file1.txt
            index git_short_hash..git_short_hash git_file_mode
            --- a/file1.txt
            +++ b/file1.txt
            @@ -1 +1 @@
            -original1
            +modified1
          EO_PATCH
        )
        # Validate Launchy was called on a file containing expected content
        expect(opened_review_files.size).to eq(1)
        expect(normalize_git_ids(reviewed_content)).to eq <<~EO_REVIEW
          1-line summary of diff from cached

          Change intent of the diff from cached

          Co-authored by X-Aeon AI Agents:
          * Test Agent
        EO_REVIEW
      end
    end
  end

  context 'when there are new untracked files' do
    it 'stages and commits the new files' do
      with_git_workspace(files: { 'existing.txt' => "existing\n" }) do
        File.write('new_file.txt', "new content\n")
        run_cli 'commit'
        git_log = Git.open(Dir.pwd).log.execute
        expect(git_log.count).to eq(2)
        expect_commit(
          git_log.first,
          <<~EO_COMMIT,
            1-line summary of diff from cached

            Change intent of the diff from cached

            Co-authored by X-Aeon AI Agents:
            * Test Agent
          EO_COMMIT
          <<~EO_PATCH
            diff --git a/new_file.txt b/new_file.txt
            new file mode git_file_mode
            index git_short_hash..git_short_hash
            --- /dev/null
            +++ b/new_file.txt
            @@ -0,0 +1 @@
            +new content
          EO_PATCH
        )
        # Validate Launchy was called on a file containing expected content
        expect(opened_review_files.size).to eq(1)
        expect(normalize_git_ids(reviewed_content)).to eq <<~EO_REVIEW
          1-line summary of diff from cached

          Change intent of the diff from cached

          Co-authored by X-Aeon AI Agents:
          * Test Agent
        EO_REVIEW
      end
    end
  end

  context 'with explicit staging strategies' do
    context 'when --stage all is used' do
      it 'stages all changes (even partially staged) and commits everything' do
        with_git_workspace(files: { 'file1.txt' => "original1\n", 'file2.txt' => "original2\n" }) do
          File.write('file1.txt', "modified1\n")
          File.write('file2.txt', "modified2\n")
          # Partially stage only file1
          `git add file1.txt`
          run_cli 'commit', '--stage', 'all'
          git_log = Git.open(Dir.pwd).log.execute
          expect(git_log.count).to eq(2)
          # Both files must be committed because :all stages everything
          expect_commit(
            git_log.first,
            <<~EO_COMMIT,
              1-line summary of diff from cached

              Change intent of the diff from cached

              Co-authored by X-Aeon AI Agents:
              * Test Agent
            EO_COMMIT
            <<~EO_PATCH
              diff --git a/file1.txt b/file1.txt
              index git_short_hash..git_short_hash git_file_mode
              --- a/file1.txt
              +++ b/file1.txt
              @@ -1 +1 @@
              -original1
              +modified1
              diff --git a/file2.txt b/file2.txt
              index git_short_hash..git_short_hash git_file_mode
              --- a/file2.txt
              +++ b/file2.txt
              @@ -1 +1 @@
              -original2
              +modified2
            EO_PATCH
          )
        end
      end
    end

    context 'when --stage if_empty is used (default)' do
      it 'does not stage additional files when the staging area is already populated' do
        with_git_workspace(files: { 'file1.txt' => "original1\n", 'file2.txt' => "original2\n" }) do
          File.write('file1.txt', "modified1\n")
          File.write('file2.txt', "modified2\n")
          # Staging area already has file1: :if_empty must NOT stage file2
          `git add file1.txt`
          run_cli 'commit', '--stage', 'if_empty'
          git_log = Git.open(Dir.pwd).log.execute
          expect(git_log.count).to eq(2)
          # Only the already-staged file1 is committed
          expect_commit(
            git_log.first,
            <<~EO_COMMIT,
              1-line summary of diff from cached

              Change intent of the diff from cached

              Co-authored by X-Aeon AI Agents:
              * Test Agent
            EO_COMMIT
            <<~EO_PATCH
              diff --git a/file1.txt b/file1.txt
              index git_short_hash..git_short_hash git_file_mode
              --- a/file1.txt
              +++ b/file1.txt
              @@ -1 +1 @@
              -original1
              +modified1
            EO_PATCH
          )
          # file2.txt must remain uncommitted in the working tree
          expect(File.read('file2.txt')).to eq("modified2\n")
          diff = Git.open(Dir.pwd).diff('HEAD')
          expect(diff.map(&:path)).to include('file2.txt')
        end
      end
    end

    context 'when --stage none is used' do
      it 'does not create a commit when there are only unstaged changes' do
        with_git_workspace(files: { 'test.txt' => "original\n" }) do
          File.write('test.txt', "modified\n")
          # Nothing staged and :none must not stage anything
          run_cli 'commit', '--stage', 'none'
          git_log = Git.open(Dir.pwd).log.execute
          expect(git_log.count).to eq(1) # Only the initial commit
        end
      end

      it 'commits only the already staged changes' do
        with_git_workspace(files: { 'file1.txt' => "original1\n", 'file2.txt' => "original2\n" }) do
          File.write('file1.txt', "modified1\n")
          File.write('file2.txt', "modified2\n")
          `git add file1.txt`
          # :none must not stage file2
          run_cli 'commit', '--stage', 'none'
          git_log = Git.open(Dir.pwd).log.execute
          expect(git_log.count).to eq(2)
          expect_commit(
            git_log.first,
            <<~EO_COMMIT,
              1-line summary of diff from cached

              Change intent of the diff from cached

              Co-authored by X-Aeon AI Agents:
              * Test Agent
            EO_COMMIT
            <<~EO_PATCH
              diff --git a/file1.txt b/file1.txt
              index git_short_hash..git_short_hash git_file_mode
              --- a/file1.txt
              +++ b/file1.txt
              @@ -1 +1 @@
              -original1
              +modified1
            EO_PATCH
          )
          # file2.txt must remain uncommitted in the working tree
          expect(File.read('file2.txt')).to eq("modified2\n")
          diff = Git.open(Dir.pwd).diff('HEAD')
          expect(diff.map(&:path)).to include('file2.txt')
        end
      end
    end
  end
end
