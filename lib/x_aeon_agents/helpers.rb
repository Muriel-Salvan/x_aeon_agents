require 'fileutils'
require 'git'
require 'launchy'
require 'octokit'
require 'open3'
require 'secret_string'

module XAeonAgents
  module Helpers
    # Exception class used to identify commands not returning the expected exit status
    class UnexpectedExitStatusError < StandardError
    end

    class << self
      include Logger

      # Retrieve API keys needed for the agents from the X-Aeon launcher
      #
      # @return [Hash{Symbol => SecretString}] The keys retrieved
      def keys_from_launcher
        @keys_from_launcher ||= begin
          keys = {
            cline_api_key: 'Cline API key',
            github_token: 'Github API token',
            openrouter_api_key: 'OpenRouter API key'
          }
          launcher_keys = {}
          Bundler.with_unbundled_env { `launcher safe -- #{keys.values.map { |launcher_key| "\"#{launcher_key}\"" }.join(' ')}` }.each_line do |line|
            next unless line =~ /^\[PASSWORD\] \[([^\]]+)\]: (.+)$/

            launcher_keys[Regexp.last_match(1)] = SecretString.new(Regexp.last_match(2))
          end
          keys.to_h { |key, launcher_key| [key, launcher_keys[launcher_key]] }
        end
      end

      # Execute a command while capturing its output in real time
      #
      # @param cmd [String] Command to be run
      # @param expected_exit_status [Integer, nil] Expected exit status, or nil for no expectation
      # @param on_start [#call(stdin, stdout, stderr, wait_thr), nil] Code called when the process has started, or nil if no code to be called
      #   - Param stdin [IO] The stdin descriptor
      #   - Param stdout [IO] The stdout descriptor
      #   - Param stderr [IO] The stderr descriptor
      #   - Param wait_thr [Process::Waiter] The wait thread
      # @param on_stdout [#call(line), nil] Code called for each line of stdout, or nil if no code to be called
      #   - Param line [String] Line of stdout
      # @param on_stderr [#call(line), nil] Code called for each line of stderr, or nil if no code to be called
      #   - Param line [String] Line of stderr
      # @return [Hash{Symbol => Object}] Command final output
      #   - stdout [String] Full stdout
      #   - stderr [String] Full stderr
      #   - exit_status [Integer] Exit status
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
      # @return [Git::Base] The git instance
      def git
        @git ||= Git.open(Dir.pwd)
      end

      # Return a list of patch description of diffs in the git staging area.
      #
      # @return [String] Patches in the staging area
      def git_diff_cached
        # TODO: Use ruby-git when the --cached feature will be implemented
        `git diff --cached`.strip
      end

      # Get a current files diffs
      #
      # @param base [String, Symbol] Git base (sha, objectish...) with which we diff, or :cached to only get diff of the staging area.
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
      # @return [Octokit::Client] The Octokit client
      def github
        @github ||= Octokit::Client.new(access_token: Config.github_token)
      end

      # Get the Github remote from the Git remotes.
      # Keep a cache of it.
      #
      # @return [Git::Remote, nil] The Github remote instance, or nil if none
      def github_remote
        @github_remote ||= git.remotes.find { |remote| remote.url.match(%r{github\.com[:/].+\.git}) }
      end

      # Get the current repository name from the Git remote URL.
      # Keep a cache of it.
      #
      # @return [String, nil] The Github repository name in the format "owner/repo", or nil if none
      def github_repo
        @github_repo ||= github_remote&.url.match(%r{github\.com[:/](.+)\.git})[1]
      end

      # Get the Ruby gem name from the gemspec file, if any.
      # Returns nil if no gemspec exists.
      #
      # @return [String, nil] The gem name, or nil
      def gem_name
        @gem_name ||= begin
          gemspec_files = Dir['*.gemspec']
          Gem::Specification.load(gemspec_files.first).name unless gemspec_files.empty?
        end
      end

      # Allow user to review and edit content before using it
      #
      # @param session_dir [String] Session directory that can be used for temporary files
      # @param name [String] Name used for the temporary file
      # @param description [String] Description shown to the user
      # @param editable [Boolean] Indicates if user can edit the content
      # @param promptable [Boolean] Indicates if user can issue a prompt as an answer
      # @param content [String] Initial content to present
      # @return [Array<String>] 2 values are returned:
      #   - [String] Content after user review (same as content if editable is false)
      #   - [String] User prompt
      def review_content(
        session_dir: '.x-aeon_agents',
        name: 'content.txt',
        description: 'Content to be reviewed',
        editable: true,
        promptable: false,
        content: ''
      )
        content_file = "#{session_dir}/reviews/#{Time.now.utc.strftime('%F-%H-%M-%S')}-#{name}"
        FileUtils.mkdir_p File.dirname(content_file)
        File.write(content_file, content)
        begin
          Launchy.open(content_file)
          puts
          puts <<~EO_STDOUT
            Review the following content: #{description}.
            #{
              (
                (editable ? ['Modify the file and save it to take your changes into consideration'] : []) + [
                  'Hit Enter to continue',
                  'Hit Ctrl-C to cancel and interrupt'
                ] + (promptable ? ['Any other input will be used to prompt again the generation of this content'] : [])
              ).map { |option| "* #{option}" }.join("\n")
            }
          EO_STDOUT
          user_prompt = $stdin.gets
          [
            editable ? File.read(content_file).strip : content,
            user_prompt.strip
          ]
        ensure
          FileUtils.rm_f content_file unless Config.debug
        end
      end
    end
  end
end
