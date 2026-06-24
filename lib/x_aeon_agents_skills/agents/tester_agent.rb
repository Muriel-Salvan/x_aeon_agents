module XAeonAgentsSkills
  module Agents
    # Agent responsible for fixing regressions induced by new features or fixes, while keeping initial requirements and implementation plan in mind.
    # If decisions in the implementation plan prevent fixing regressions, modify the implementation plan and report those modifications.
    class TesterAgent < ComposableAgents::Cline::Agent
      prepend XAeonAgentsSkills::AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          requirements: 'The initial requirements',
          plan: 'The implementation plan devised from the requirements',
          files_diffs: 'The full list of files changes and differences that have been done to implement the initial requirements following the implementation plan',
          tests_output: 'The output of running the whole tests suite',
          tests_cmd: 'The command line to be used to run the whole tests suite'
        }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {
          plan_modifications: 'The modification or divergence you considered from the implementation plan'
        }
      end

      # Constructor
      #
      # @param agent_params [Hash<Symbol, Object>] Parameters driving the agent model selection
      def initialize(**agent_params)
        super(
          name: 'Tester',
          objective: <<~EO_OBJECTIVE,
            Fix any regression that has been induced by new features or fixes, while keeping the initial requirements and implementation plan in mind.
            If the decisions taken in the implementation plan prevent you from fixing regressions, modify the implementation plan and report those modifications to the user.
          EO_OBJECTIVE
          **agent_params
        )
      end
    end
  end
end
