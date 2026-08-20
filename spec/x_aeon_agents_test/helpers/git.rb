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

      # Mock git pushes made by the production code, regardless of the code path
      # used to invoke them: the Git Ruby gem's ProcessExecuter.run_with_capture
      # abstraction, or Helpers.run_cmd which uses Open3.popen3 directly.
      #
      # Only the git push call is mocked: any other git command is forwarded to
      # the original implementation so that it really runs.
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
        # Also intercept git push commands issued through Helpers.run_cmd, which
        # uses Open3.popen3 directly rather than the Git Ruby gem's ProcessExecuter
        # abstraction. We use stub_command (which mocks Open3.popen3) so that
        # non-push run_cmd calls (e.g. VSCodium) can be independently stubbed by the
        # tests via stub_command as well, without interference.
        stub_command(
          /git push/,
          stdout: proc do |cmd|
            cmd_tokens = cmd.to_s.split
            push_idx = cmd_tokens.index('push')
            git_pushes << cmd_tokens[(push_idx + 1)..] if push_idx&.positive?
            ''
          end
        )
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
      #   Each information is the git command tokens that followed the 'push' token,
      #   issued either through the Git Ruby gem (via ProcessExecuter) or through
      #   Helpers.run_cmd (via Open3). Options, the remote name and the branch
      #   are included.
      #   For example:
      #   - ["--force", "origin", "feature-branch"]
      #   - ["--set-upstream", "github", "feature/new-task"]
      attr_reader :git_pushes
    end
  end
end
