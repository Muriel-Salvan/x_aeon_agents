module XAeonAgents
  module Agents
    # Agent responsible for opening a new git worktree for a task.
    class TaskStarterAgent < ComposableAgents::Agent
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
        # TODO: Raise an exception with a proper message if the directory exists but is not a worktree + Add 1 test case about it.
        # TODO: Raise an exception with a proper message if the directory exists and is a worktree on a different branch + Add 1 test case about it.
        unless File.directory?(dir)
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
