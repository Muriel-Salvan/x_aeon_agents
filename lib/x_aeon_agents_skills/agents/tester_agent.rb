module XAeonAgentsSkills
  module Agents
    # Agent responsible for fixing regressions induced by new features or fixes, while keeping initial requirements and implementation plan in mind.
    # If decisions in the implementation plan prevent fixing regressions, modify the implementation plan and report those modifications.
    class TesterAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          requirements: 'Initial requirements',
          plan: 'Implementation plan devised from the requirements',
          files_diffs: 'Full list of files changes and differences that have been done to implement the initial requirements following the implementation plan',
          tests_output: 'Output of running the whole tests suite',
          tests_cmd: 'Command line to be used to run the whole tests suite'
        }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {
          plan_modifications: 'Modification or divergence you considered from the implementation plan'
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
          instructions: {
            ordered_list: [
              <<~EO_STEP,
                Understand the initial requirements from the artifact named `requirements`

                - Understand those requirements and their intent.
              EO_STEP
              <<~EO_STEP,
                Understand the implementation plan from the artifact named `plan`

                - Understand all the steps of the implementation plan.
              EO_STEP
              <<~EO_STEP,
                Understand the file changes from the artifact named `files_diffs`

                - Understand what was the intent of the developer implementing the requirements.
              EO_STEP
              <<~EO_STEP,
                Analyze the full output of unit tests run from the artifact named `tests_output`

                - Check every error reported in the output.
              EO_STEP
              'Fix any issue that unit tests are surfacing, while keeping the original intent of the requirements',
              'Remember any inconsistency and modification you need to make to the implementation plan so that your fixes are in-line with a better implementation plan',
              <<~EO_STEP
                Make sure all tests are running without issue after your fixes

                - You can run tests again using the provided tests command from the artifact named `tests_cmd` to test your own fixes.
              EO_STEP
            ]
          },
          **agent_params
        )
      end
    end
  end
end
