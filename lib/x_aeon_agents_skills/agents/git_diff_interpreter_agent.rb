module XAeonAgentsSkills
  module Agents
    # Agent responsible for analyzing git differences with a given git ref base.
    # The git ref base is given in the git_ref_base input artifact.
    # For the staging area diff, use cached as the git_ref_base content.
    class GitDiffInterpreterAgent < ComposableAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        { git_ref_base: 'Git reference used to diff with' }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {
          change_intent: 'Full description of the code changes, their meaning and intent',
          one_line_summary: '1-line summary of the code change intent'
        }
      end

      # Constructor
      def initialize
        super(name: 'Git Diff Interpreter')
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param git_ref_base [String] The git reference to diff with. Use 'cached' for the staging area.
      # @param input_artifacts [Hash<Symbol,Object>] The input artifacts content
      # @return Hash<Symbol,Object> Output artifacts content
      def run(git_ref_base:, **_input_artifacts)
        change_intent = diff_interpreter_agent.run(
          files_diff: Helpers.artifact_files_diffs(git_ref_base == 'cached' ? :cached : git_ref_base)
        )[:change_intent]
        {
          change_intent:,
          one_line_summary: OneLineCodeDiffSummarizerAgent.new(**Models.free_simple).run(change_intent:)[:one_line_summary]
        }
      end

      # Get a Diff Interpreter agent.
      #
      # @return [Agent] The Diff Interpreter agent
      def diff_interpreter_agent
        @diff_interpreter_agent ||= DiffInterpreterAgent.new(**Models.free_simple)
      end
    end
  end
end
