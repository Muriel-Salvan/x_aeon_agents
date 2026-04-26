require 'fileutils'
require 'open3'

module XAeonAgentsSkills

  module Helpers

    # Exception class used to identify commands not returning the expected exit status
    class UnexpectedExitStatusError < StandardError
    end

    class << self

      include Logger

      # Retrieve API keys needed for the agents from the X-Aeon launcher
      #
      # @return [Hash<Symbol, String>] The keys retrieved
      def keys_from_launcher
        keys = {
          cline_api_key: 'Cline API key',
          github_token: 'Github API token',
          openrouter_api_key: 'OpenRouter API key'
        }
        launcher_keys = {}
        Bundler.with_unbundled_env { `launcher safe -- #{keys.values.map { |launcher_key| "\"#{launcher_key}\"" }.join(' ')}` }.each_line do |line|
          next unless line =~ /^\[PASSWORD\] \[([^\]]+)\]: (.+)$/

          launcher_keys[Regexp.last_match(1)] = Regexp.last_match(2)
        end
        keys.to_h { |key, launcher_key| [key, launcher_keys[launcher_key]] }
      end

      # Setup a temporary directory.
      # In case of debug activated, create the temporary directory from the current one and don't delete it, following this pattern:
      # .x-aeon_agents/#{sub_dir}/{unique_id}#{suffix}
      # {unique_id} is computed using Time.now in utc and gets an extra index to avoid conflicts.
      #
      # Parameters::
      # * *sub_dir* (String): Sub-directory appended to the temp dir. Only used in case of debug. [default: '/tmp']
      # * *suffix* (String): Suffix used after the directory name [default: '']
      # * *block* (Proc): Code called with the temp dir created
      #   * Parameters::
      #     * *temp_dir* (String): The temporary directory
      def with_temp_dir(sub_dir: 'tmp', suffix: '', &block)
        if Logger.debug
          temp_dir = nil
          unique_idx = 0
          loop do
            temp_dir = ".x-aeon_agents/#{sub_dir}/#{Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S')}-#{unique_idx}#{suffix}"
            break unless File.exist?(temp_dir)
            unique_idx += 1
          end
          FileUtils.mkdir_p temp_dir
          block.call(temp_dir)
        else
          Dir.mktmpdir(&block)
        end
      end

      # Deep merge two hashes recursively, preserving nested structures
      #
      # Parameters::
      # * *target* (Hash): Hash in which we merge the source
      # * *source* (Hash): Hash that we meerge in the target (overriding its values)
      # Result::
      # * Hash: Merged hash
      def deep_merge(target, source)
        target.merge(source) do |_key, oldval, newval|
          if oldval.is_a?(Hash) && newval.is_a?(Hash)
            deep_merge(oldval, newval)
          else
            newval
          end
        end
      end

      # Execute a command while capturing its output in real time
      #
      # Parameters::
      # * *cmd* (String): Command to be run
      # * *expected_exit_status* (Integer or nil): Expected exit status, or nil for no expectation [default: 0]
      # * *on_start* (Proc or nil): Code called when the process has started, or nil if no code to be called [default: nil]
      #   * Parameters::
      #     * *stdin* (Object): The stdin descriptor
      #     * *stdout* (Object): The stdout descriptor
      #     * *stderr* (Object): The stderr descriptor
      #     * *wait_thr* (Object): The wait thread
      # * *on_stdout* (Proc or nil): Code called for each line of stdout, or nil if no code to be called [default: nil]
      #   * Parameters::
      #     * *line* (String): Line of stdout
      # * *on_stderr* (Proc or nil): Code called for each line of stderr, or nil if no code to be called [default: nil]
      #   * Parameters::
      #     * *line* (String): Line of stderr
      # Result::
      # * Hash<Symbol,Object>: Command final output:
      #   * *stdout* (String): Full stdout
      #   * *stderr* (String): Full stderr
      #   * *exit_status* (Integer): Exit status
      def run_cmd(cmd, expected_exit_status: 0, on_start: nil, on_stdout: nil, on_stderr: nil)
        stdout_lines = []
        stderr_lines = []
        exit_status = nil
        Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
          on_start.call(stdin, stdout, stderr, wait_thr) if on_start
          stdin.close
          [
            # Parse stdout
            Thread.new do
              stdout.each_line do |line|
                stdout_lines << line
                on_stdout.call(line) unless on_stdout.nil?
              end
            end,
            # Parse stderr
            Thread.new do
              stderr.each_line do |line|
                stderr_lines << line
                on_stderr.call(line) unless on_stderr.nil?
              end
            end
          ].each(&:join)
          exit_status = wait_thr.value.exitstatus
          log_debug "CLI `#{cmd}` exited with status: #{exit_status}"
          raise UnexpectedExitStatusError.new("CLI `#{cmd}` exited with status #{exit_status} (expected #{expected_exit_status})") if !expected_exit_status.nil? && exit_status != expected_exit_status
        end
        {
          stdout: stdout_lines.join("\n"),
          stderr: stderr_lines.join("\n"),
          exit_status:
        }
      end

      # Get a Git instance on the current directory.
      # Keep a cache of it.
      #
      # Result::
      # * Git::Base: The git instance
      def git
        @git ||= Git.open(Dir.pwd)
      end

      # Return a list of patch description of diffs in the git staging area.
      #
      # Result::
      # * String: Patches in the staging area
      def git_diff_cached
        # TODO: Use ruby-git when the --cached feature will be implemented
        `git diff --cached`.strip
      end

      # Get a current files diffs
      #
      # Parameters::
      # * *base* (Object): Git base (sha, objectish...) with which we diff, or :cached to only get diff of the staging area [default = 'HEAD']
      def artifact_files_diffs(base = 'HEAD')
        if base == :cached
          <<~EO_Artifact
            ### git diff --cached

            ```
            #{git_diff_cached}
            ```
          EO_Artifact
        else
          <<~EO_Artifact
            ### New untracked files

            #{git.status.untracked.keys.map do |file|
              <<~EO_Untracked_File
                #### #{file}
                ```
                #{File.read(file)}
                ```
              EO_Untracked_File
            end.join("\n")}

            ### git diff

            ```
            #{git.diff(base)}
            ```
          EO_Artifact
        end
      end

      # Get a Github Octokit API instance.
      # Keep a cache of it.
      #
      # Result::
      # * Octokit::Client: The Octokit client
      def github
        @github ||= Octokit::Client.new(access_token: Configuration.config[:github_token])
      end

      # Get the Github remote from the Git remotes.
      # Keep a cache of it.
      #
      # Result::
      # * Git::Remote: The Github remote instance
      def github_remote
        @github_remote ||= begin
          remote = git.remotes.find { |remote| remote.url.match(%r{github\.com[:/].+\.git}) }
          raise 'Can\'t find a Github remote in this repository' if remote.nil?
          remote
        end
      end

      # Get the current repository name from the Git remote URL.
      # Keep a cache of it.
      #
      # Result::
      # * String: The repository name in the format "owner/repo"
      def github_repo
        @github_repo ||= github_remote.url.match(%r{github\.com[:/](.+)\.git})[1]
      end

    end

  end

end
