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

      # Mock the ProcessExecuter calls made internally by the Git Ruby gem when
      # pushing. The Git gem relies on ProcessExecuter.run_with_capture to execute
      # git commands, so we mock this implementation rather than the Git#push
      # interface. This way the real Git#push code (including its option
      # validation) runs, and any wrong usage of the Git interface in the
      # production code is caught by the tests.
      #
      # Only the git push call is mocked: any other git command is forwarded to
      # the original ProcessExecuter.run_with_capture so that it really runs.
      def mock_git_push
        @git_pushes = []
        allow(::ProcessExecuter).to receive(:run_with_capture).and_wrap_original do |original_run_with_capture, *args, **kwargs|
          # The push command is identified by its git command tokens.
          push_idx = args.index('push')
          if push_idx&.positive?
            # Record the git command after the 'push' token (options + remote name + branch)
            git_pushes << args[(push_idx + 1)..]
            # Return a fabricated successful process result so the Git gem
            # considers the push as executed successfully. Only the methods the
            # Git gem relies on are defined.
            Struct.new(:command, :stdout, :stderr, :exitstatus) do
              def success? = true

              def signaled? = false

              def timed_out? = false
            end.new(args, '', '', 0)
          else
            original_run_with_capture.call(*args, **kwargs)
          end
        end
      end

      # Mock Git#remotes on opened Git instances so the application sees a set of
      # fake remotes. Useful for tests that generate README badges from the
      # repository name (e.g. the README generator).
      #
      # @param remotes [Hash{String => String}] A map of remote name => remote url
      #   to return when the application calls Git#remotes. Defaults to a single
      #   fake Github remote pointing to 'https://github.com/test-owner/test-repo.git'.
      def mock_git_remotes(
        remotes: { 'origin' => 'https://github.com/test-owner/test-repo.git' }
      )
        allow(::Git).to receive(:open).and_wrap_original do |original_open, *args, **kwargs|
          git_instance = original_open.call(*args, **kwargs)
          allow(git_instance).to receive(:remotes).and_return(
            remotes.map { |name, url| Struct.new(:name, :url).new(name, url) }
          )
          git_instance
        end
      end

      # @return [Array<Array<String>>] The list of git pushes that were performed.
      #   Each information is the git command tokens that were passed to
      #   ProcessExecuter.run_with_capture by the Git gem for a push, stripped of
      #   the environment hash, the git binary path and the 'push' command name.
      #   For example:
      #   - ["--force", "origin", "feature-branch"]
      #   - ["github", "feature/new-task"]
      attr_reader :git_pushes
    end
  end
end
