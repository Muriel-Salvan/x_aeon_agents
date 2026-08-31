module XAeonAgents
  module Agents
    # Agent responsible for opening a new git worktree for a task.
    class TaskStarterAgent < ComposableAgents::Agent
      # Exception raised when the target worktree directory is invalid
      # (already exists but is not a git worktree, or is a worktree on a
      # different branch than the requested one).
      class TaskStarterError < StandardError
      end

      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        { branch_name: 'The name of the git branch to create worktree for' }
      end

      # Define output artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        { worktree_dir: 'The directory where the worktree was created' }
      end

      # Execute the agent to open a new git worktree for a feature branch.
      #
      # @param branch_name [String] Name of the git branch to create worktree for
      # @return [Hash{Symbol => Object}] Output artifacts content
      def run(branch_name:)
        dir = ".worktrees/#{branch_name.tr('/', '_')}"
        puts "Setting worktree #{dir} to work on branch #{branch_name}..."
        # Create the branch if it does not exist (without checking it out)
        Helpers.git.branch(branch_name).create unless Helpers.git.branches.any? { |branch| branch.name == branch_name }
        # Create the git worktree only if it does not exist yet (idempotent)
        if File.directory?(dir)
          # The directory already exists: it must be a git worktree for the requested branch.
          # A git worktree has a `.git` file (a gitdir pointer), not a `.git` directory.
          unless File.file?(File.join(dir, '.git'))
            raise TaskStarterError, <<~EO_MSG.strip
              Directory '#{dir}' already exists but is not a git worktree (no '.git' pointer file found).
              Please remove it or choose a different branch name.
            EO_MSG
          end

          # The directory is a worktree: ensure it tracks the requested branch.
          worktree_branch = Git.open(dir).current_branch
          if worktree_branch != branch_name
            raise TaskStarterError, <<~EO_MSG.strip
              Directory '#{dir}' is already a git worktree on branch '#{worktree_branch}', which differs from the requested branch '#{branch_name}'.
              Please choose a different branch name or remove the existing worktree.
            EO_MSG
          end
        else
          # Call git worktree add on existing branches only
          Helpers.git.lib.worktree_add(dir, branch_name)
          # Install the project's dependencies in the fresh worktree, as configured
          setup_fresh_worktree(dir)
        end
        # Push to remote if branch doesn't exist there yet
        # TODO: Use ruby-git when the --set-upstream option will be supported by its push method
        # (ruby-git 4.x validates push options against PUSH_OPTION_MAP, which does not include
        # set_upstream, so we fall back to a raw git command that both pushes and sets the
        # upstream tracking in a single atomic operation.)
        Helpers.run_cmd("git push --set-upstream #{Helpers.github_remote.name} #{branch_name}")
        # Execute the configured callback notifying that a new worktree has been opened
        open_worktree(dir)
        { worktree_dir: dir }
      end

      private

      # Execute the steps installing the project's dependencies in a fresh worktree, as
      # defined by the optional setup_project method of the config DSL. Do nothing if the
      # config does not define any setup step.
      #
      # @param dir [String] The fresh worktree directory in which to execute the setup steps
      def setup_fresh_worktree(dir)
        setup_proc = Config.setup_project_proc
        return if setup_proc.nil?

        puts "Setting up project dependencies in fresh worktree #{dir}..."
        Dir.chdir(dir) { setup_proc.call }
      end

      # Execute the callback notifying a worktree has been opened, as defined by the optional
      # on_open_worktree method of the config DSL. Do nothing if the config does not define any
      # callback.
      #
      # @param dir [String] The worktree directory that has been opened
      def open_worktree(dir)
        open_proc = Config.open_worktree_proc
        return if open_proc.nil?

        open_proc.call(dir)
      end
    end
  end
end
