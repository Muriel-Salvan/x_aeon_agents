module XAeonAgents
  module Agents
    # Agent responsible for analyzing git differences with a given git ref base.
    # The git ref base is given in the git_ref_base input artifact.
    # For the staging area diff, use cached as the git_ref_base content.
    class GitDiffInterpreterAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        { git_ref_base: 'Git reference used to diff with' }
      end

      # Define output artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {
          change_intent: 'Full description of the code changes, their meaning and intent',
          one_line_summary: '1-line summary of the code change intent'
        }
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(name: 'Git Diff Interpreter', **agent_params)
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param git_ref_base [String] The git reference to diff with. Use 'cached' for the staging area.
      # @return [Hash{Symbol => Object}] Output artifacts content
      def run(git_ref_base:)
        step_agent(
          diff_interpreter_agent,
          files_diff: Helpers.artifact_files_diffs(git_ref_base == 'cached' ? :cached : git_ref_base)
        )
        step_agent(new_agent(OneLineCodeDiffSummarizerAgent, **Config.agent_options['free_simple']))
        {
          change_intent: @artifacts[:change_intent],
          one_line_summary: @artifacts[:one_line_summary]
        }
      end

      # Get a Diff Interpreter agent.
      #
      # @return [Agent] The Diff Interpreter agent
      def diff_interpreter_agent
        @diff_interpreter_agent ||= new_agent(DiffInterpreterAgent, **Config.agent_options['free_simple'])
      end
    end
  end
end
