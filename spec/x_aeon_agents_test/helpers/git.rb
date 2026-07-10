require 'git'

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
      # optionally check out a branch and add remotes, then yield for the
      # test to make modifications and run the CLI.
      #
      # @param files [Hash{String => String}] Initial files to create and commit
      # @param branch [String, nil] If given, create and checkout this branch after the initial commit
      # @param remotes [Hash{String => String}, nil] If given, add each remote name => url pair
      # @yield Test code that will execute inside the git initialized workspace.
      def with_git_workspace(files: {}, branch: nil, remotes: nil)
        Dir.chdir(temp_dir) do
          git_base = ::Git.init(Dir.pwd)
          git_base.config('user.email', 'test@example.com')
          git_base.config('user.name', 'Test User')
          unless files.empty?
            files.each do |name, content|
              File.write(name, content)
              git_base.add(name)
            end
            git_base.commit('Initial commit')
          end
          git_base.branch(branch).checkout if branch
          remotes&.each { |name, url| git_base.add_remote(name, url) }
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

      # Mock Git#push on the next Git instance
      def mock_git_push
        @git_pushes = []
        allow(::Git).to receive(:open).and_wrap_original do |original_open, *args, **kwargs|
          @git_instance = original_open.call(*args, **kwargs)
          allow(git_instance).to receive(:push) do |remote, branch, **options|
            git_pushes << {
              url: remote.url,
              branch:,
              options:
            }
            nil
          end
          git_instance
        end
      end

      # @return [Array<Hash{Symbol => Object}>] The list of Git pushes that were performed.
      #   Each information has the following properties:
      #   - url [String] URL on which the push was performed.
      #   - branch [String] Branch name that was pushed.
      #   - options [Hash] Additional options for this push
      attr_reader :git_pushes

      # @return [Git::Base, nil] The last opened Git instance that has push mocked, or nil if none
      attr_reader :git_instance
    end
  end
end
