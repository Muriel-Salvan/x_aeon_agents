require 'fileutils'
require 'git'
require 'launchy'
require 'octokit'
require 'open3'

module XAeonAgents
  # Various helpers and utilities that are used internally
  module Helpers
    # Exception class used to identify commands not returning the expected exit status
    class UnexpectedExitStatusError < StandardError
    end

    class << self
      # Execute a command while capturing its output in real time
      #
      # @param cmd [String] Command to be run
      # @param expected_exit_status [Integer, nil] Expected exit status, or nil for no expectation
      # @return [Hash{Symbol => Object}] Command final output
      #   - stdout [String] Full stdout
      #   - stderr [String] Full stderr
      #   - exit_status [Integer] Exit status
      def run_cmd(cmd, expected_exit_status: 0)
        stdout = nil
        stderr = nil
        exit_status = nil
        stdout_lines = []
        stderr_lines = []
        Open3.popen3(cmd) do |cmd_stdin, cmd_stdout, cmd_stderr, wait_thr|
          cmd_stdin.close
          [
            # Parse stdout
            Thread.new do
              cmd_stdout.each_line do |line|
                stdout_lines << line
              end
            end,
            # Parse stderr
            Thread.new do
              cmd_stderr.each_line do |line|
                stderr_lines << line
              end
            end
          ].each(&:join)
          exit_status = wait_thr.value.exitstatus
          stdout = stdout_lines.join
          stderr = stderr_lines.join
          Config.logger.debug "Command `#{cmd}` exited with status: #{exit_status}"
          Config.logger.debug <<~EO_DEBUG_OUTPUT
            ===== STDOUT
            #{stdout}
            ===== STDERR
            #{stderr}
            ===== END OF STDERR
          EO_DEBUG_OUTPUT
          if !expected_exit_status.nil? && exit_status != expected_exit_status
            raise UnexpectedExitStatusError, "Command `#{cmd}` exited with status #{exit_status} (expected #{expected_exit_status})"
          end
        end
        {
          stdout:,
          stderr:,
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
          <<~EO_ARTIFACT
            ### git diff --cached

            ```
            #{git_diff_cached}
            ```
          EO_ARTIFACT
        else
          <<~EO_ARTIFACT
            ### New untracked files

            #{git.status_info.untracked.keys.map do |file|
              <<~EO_UNTRACKED_FILE
                #### #{file}
                ```
                #{File.read(file)}
                ```
              EO_UNTRACKED_FILE
            end.join("\n")}

            ### git diff

            ```
            #{git.diff(base)}
            ```
          EO_ARTIFACT
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
        @github_repo ||= github_remote && github_remote.url.match(%r{github\.com[:/](.+)\.git})[1]
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

      # Get the system instructions telling agents in which repository they are working.
      # This instruction is format-agnostic: it does not include any formatting (bullet, header...) so that it can be
      # included in any system instructions section.
      #
      # @return [String] The system instructions about the current repository
      def repository_access_system_instructions
        "The current repository in which you are working is `#{Dir.pwd}`."
      end

      # Get the constraint restricting the files agents are allowed to access.
      # Constraints are rendered as Markdown bullet lists: the returned sentence includes its own bullet prefix.
      #
      # @param writable [Boolean] True if the agent is allowed to write files, false if it is read-only
      # @return [String] The constraint restricting the agents' file accesses to the current repository
      def repository_access_constraint(writable: false)
        "- You should only #{writable ? 'read and write' : 'read'} files that are part of the current repository: `#{Dir.pwd}`"
      end

      # Get the constraint allowing agents to access their artifact files, which can be located outside of the
      # current repository.
      # Constraints are rendered as Markdown bullet lists: the returned sentence includes its own bullet prefix.
      # A nil is returned when no artifact path is given, so that callers can interpolate the result
      # unconditionally in an array of constraint lines and simply compact the array.
      #
      # @param artifact_paths [Array<String>] Absolute paths of the artifact files the agent is allowed to access
      # @return [String, nil] The constraint about artifact files access, or nil when no artifact path is given
      def artifacts_access_constraint(*artifact_paths)
        return nil if artifact_paths.empty?

        '- You are allowed to read and write the artifact files at ' \
          "#{artifact_paths.map { |artifact_path| "`#{artifact_path}`" }.join(', ')}, " \
          'even if they are not part of the current repository'
      end

      # Get the constraint forbidding the agent from using the ask_question tool when no human user is available.
      # Constraints are rendered as Markdown bullet lists: the returned sentence includes its own bullet prefix.
      # A nil is returned when the interactive mode is enabled, so that callers can interpolate the result
      # unconditionally in an array of constraint lines and simply compact the array.
      #
      # @return [String, nil] The constraint about not asking questions, or nil when the interactive mode is enabled
      def non_interactive_constraint
        return nil if Config.interactive

        '- You MUST NOT use the ask_question tool under any circumstances: ' \
          'you are running in non-interactive mode with no human user available, ' \
          'so proceed using your best judgment without asking'
      end

      # Get the constraint explaining how to use the tools that are available to agents of the Cline kind.
      # Constraints are rendered as Markdown bullet lists: the returned sentences include their own bullet prefixes.
      #
      # @return [String] The constraint about using the tools available to Cline agents
      def cline_tools_constraint
        <<~EO_CONSTRAINT.rstrip
          - The `run_commands` tool takes ONE shell script as a plain string.
            - NEVER wrap it in `[ ]` or JSON.
            - One command per call; chain commands with `&&` only on one line.
            - Never use multi-line heredocs.
          - Always use the `editor` tool to write files.
          - You are a single agent: there is no team. NEVER call `team_*` tools: they will fail and count as mistakes.
        EO_CONSTRAINT
      end

      # Allow user to review and edit content before using it
      #
      # When the interactive mode is disabled (Config.interactive), no review file
      # is written, nothing is opened and no user input is asked: the given content
      # is accepted as-is and an empty user prompt is returned.
      #
      # @param reviews_dir [String] Directory that can be used to store files to be reviewed
      # @param name [String] Name used for the temporary file
      # @param description [String] Description shown to the user
      # @param editable [Boolean] Indicates if user can edit the content
      # @param promptable [Boolean] Indicates if user can issue a prompt as an answer
      # @param content [String] Initial content to present
      # @return [Array<String>] 2 values are returned:
      #   - [String] Content after user review (same as content if editable is false or the interactive mode is disabled)
      #   - [String] User prompt (empty when the interactive mode is disabled)
      def review_content(
        reviews_dir: "#{Config.data_dir}/reviews",
        name: 'content.txt',
        description: 'Content to be reviewed',
        editable: true,
        promptable: false,
        content: ''
      )
        # When the interactive mode is disabled, accept the content as-is without
        # writing any review file nor asking anything to the user.
        return [content, ''] unless Config.interactive

        content_file = "#{reviews_dir}/#{Time.now.utc.strftime('%F-%H-%M-%S')}-#{name}"
        FileUtils.mkdir_p File.dirname(content_file)
        File.write(content_file, content)
        begin
          Launchy.open(content_file)
          Config.logger << ''
          Config.logger << <<~EO_STDOUT
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
