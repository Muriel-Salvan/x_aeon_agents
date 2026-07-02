module XAeonAgents
  module Agents
    # Agent responsible for opening a new git worktree for a task.
    class TaskStarterAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        { branch_name: 'Name of the git branch to create worktree for' }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        { worktree_dir: 'Directory where the worktree was created' }
      end

      # Execute the agent to open a new git worktree for a feature branch.
      #
      # @param branch_name [String] Name of the git branch to create worktree for
      # @return Hash<Symbol,Object> Output artifacts content
      def run(branch_name:)
        dir = ".worktrees/#{branch_name.tr('/', '_')}"

        puts "Setting worktree #{dir} to work on branch #{branch_name}..."

        # Create the branch if it does not exist (without checking it out)
        system "git branch #{branch_name}"

        # Call git worktree add on existing branches only
        system "git worktree add #{dir} #{branch_name}", exception: true

        # Push to remote if branch doesn't exist there yet
        system "git push --set-upstream github #{branch_name}", exception: true
        system "VSCodium.exe \"#{dir}\"", exception: true

        { worktree_dir: dir }
      end
    end
  end
end
