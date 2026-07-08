module XAeonAgentsTest
  module Helpers
    module Git
      # Normalize the stdout by replacing generated git hashes with placeholders
      # so that the full HEREDOC validation works predictably.
      #
      # @param stdout [String] The raw stdout to normalize
      # @return [String] The normalized stdout
      def normalize_git_ids(str)
        str
          .gsub(/index [0-9a-f]+\.\.[0-9a-f]+ \d+/, 'index git_short_hash..git_short_hash git_file_mode')
          .gsub(/[0-9a-f]{40}/, 'git_commit_hash')
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
    end
  end
end
