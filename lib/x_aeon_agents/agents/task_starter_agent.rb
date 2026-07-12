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
        end
        # Push to remote if branch doesn't exist there yet
        Helpers.git.push(Helpers.github_remote, branch_name, set_upstream: true)
        Helpers.run_cmd("VSCodium.exe \"#{dir}\"")
        { worktree_dir: dir }
      end
    end
  end
end
