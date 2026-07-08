module XAeonAgentsTest
  module Helpers
    module Git
      # Normalize the stdout by replacing generated git hashes with placeholders
      # so that the full HEREDOC validation works predictably.
      #
      # @param str [String] The raw string to normalize
      # @return [String] The normalized string
      def normalize_git_ids(str)
        str
          .gsub(/index [0-9a-f]+\.\.[0-9a-f]+ \d+/, 'index git_short_hash..git_short_hash git_file_mode')
          .gsub(/index [0-9a-f]+\.\.[0-9a-f]+(?=\s|$)/, 'index git_short_hash..git_short_hash')
          .gsub(/[0-9a-f]{40}/, 'git_commit_hash')
          .gsub(/\bnew file mode \d+\b/, 'new file mode git_file_mode')
          .gsub(/\bdeleted file mode \d+\b/, 'deleted file mode git_file_mode')
          .gsub(/\bold mode \d+\b/, 'old mode git_file_mode')
      end

      # Validate that the normalized stdout includes the expected output.
      # Replaces the common pattern `expect(normalize_git_ids(stdout)).to include expected_stdout`.
      #
      # @param expected_stdout [String] The expected stdout content to check for inclusion
      def expect_stdout(expected_stdout)
        expect(normalize_git_ids(stdout)).to include expected_stdout
      end

      # Create a temporary git workspace outside the project tree so that
      # Git.open finds the workspace's own .git (not the parent project's).
      # Initialize it as a Git repository, create and commit initial files,
      # then yield for the test to make modifications and run the CLI.
      #
      # @param files [Hash{String => String}] Initial files to create and commit
      # @yield Test code that will execute inside the git initialized workspace.
      def with_git_workspace(files: {})
        Dir.chdir(temp_dir) do
          # TODO: Use the Git library instead of external commands
          `git init`
          `git config user.email "test@example.com"`
          `git config user.name "Test User"`
          unless files.empty?
            git_base = ::Git.open(Dir.pwd)
            files.each do |name, content|
              File.write(name, content)
              git_base.add(name)
            end
            git_base.commit('Initial commit')
          end
          yield
        end
      end

      # Expect a commit to match a given message and patch
      #
      # @param commit [Git::Object::Commit] The commit to validate
      # @param message [String] The expected commit message
      # @param patch [String] The expected commit patch
      def expect_commit(commit, message, patch)
        expect(normalize_git_ids(commit.message).strip).to eq message.strip
        expect(normalize_git_ids(::Git.open(Dir.pwd).diff("#{commit.sha}^", commit.sha).patch).strip).to eq patch.strip
      end
    end
  end
end
