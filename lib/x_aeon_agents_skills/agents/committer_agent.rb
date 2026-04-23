require 'launchy'

module XAeonAgentsSkills
  module Agents
    # Agent responsible for git committing locally staged or modified files
    class CommitterAgent < ComposableAgents::Agent
      # Constructor
      def initialize
        super(name: 'Committer')
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param input_artifacts [Hash<Symbol,Object>] The input artifacts content
      # @return Hash<Symbol,Object> Output artifacts content
      def run(**_input_artifacts)
        # If nothing is staged, stage everything
        Helpers.git.add(all: true) if Helpers.git_diff_cached.empty?
        git_diff_interpreter_agent_output = GitDiffInterpreterAgent.new.run(git_ref_base: 'cached')
        commit_file = '.x-aeon_agents/commit.md'
        FileUtils.mkdir_p File.dirname(commit_file)
        File.write(
          commit_file,
          <<~EO_COMMIT
            #{git_diff_interpreter_agent_output[:one_line_summary].strip}

            #{git_diff_interpreter_agent_output[:change_intent].strip}

            Co-authored by: X-Aeon Agent #{git_diff_interpreter_agent_output[:agent_author].strip}
          EO_COMMIT
        )
        begin
          Launchy.open(commit_file)
          puts
          puts 'Review and edit the commit file description and hit Enter to create the commit or Ctrl-C to cancel...'
          $stdin.gets
          Helpers.git.commit File.read(commit_file).strip
          puts 'Commit created successfully.'
        ensure
          FileUtils.rm_f commit_file
        end
      end
    end
  end
end
