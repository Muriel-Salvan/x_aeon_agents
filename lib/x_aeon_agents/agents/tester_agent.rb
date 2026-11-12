module XAeonAgents
  module Agents
    # Agent responsible for fixing regressions induced by new features or fixes, while keeping initial requirements and implementation plan in mind.
    # If decisions in the implementation plan prevent fixing regressions, modify the implementation plan and report those modifications.
    class TesterAgent < ComposableAgents::Cline::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        super.merge(
          requirements: {
            description: 'The initial requirements',
            type: :markdown
          },
          plan: {
            description: 'The implementation plan devised from the requirements',
            type: :markdown
          },
          files_diffs: {
            description: 'The full list of files changes and differences that have been done to implement the initial ' \
              'requirements following the implementation plan',
            type: :text
          },
          tests_output: {
            description: 'The output of running the whole tests suite',
            type: :text
          },
          tests_cmd: {
            description: 'The command line to be used to run the whole tests suite',
            type: :text
          }
        )
      end

      # Define output artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        super.merge(
          plan_modifications: {
            description: 'The modification or divergence you considered from the implementation plan',
            type: :markdown,
            optional: true
          }
        )
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(
          name: 'Tester',
          objective: <<~EO_OBJECTIVE,
            Fix any regression that has been induced by new features or fixes, while keeping the initial requirements and implementation plan in mind.
            If the decisions taken in the implementation plan prevent you from fixing regressions, modify the implementation plan and report those modifications to the user.
          EO_OBJECTIVE
          **agent_params
        )
        self.constraints = <<~EO_CONSTRAINTS
          - #{Helpers.repository_access_constraint(writable: true)}
          - #{Helpers.artifacts_access_constraint(artifact_ref(:plan_modifications))}
        EO_CONSTRAINTS
        self.system_instructions = <<~EO_INSTRUCTIONS
          #{Helpers.repository_access_system_instructions}

          Always gather all the necessary context before starting to work on a task.
          For example, make sure you understand the regressions to fix, the naming conventions, frameworks and libraries used and aligned in the current codebase, and the environment and commands used to run and test the code etc.
          Always run the whole tests suite using the tests command provided, and validate your fixes with live feedback until all tests pass.
          Begin by analyzing the user's input and gathering any necessary additional context.
          Then, present your plan at the start of your response along with tool calls before proceeding with the task.
          It's OK for this section to be quite long.

          Review each question carefully and answer it with detailed, accurate information.

          If you need more information, use one of the available tools or ask for clarification instead of making assumptions or lies.

          Fix __all__ issues reported in the tests output file `#{artifact_ref(:tests_output)}` in this iteration (not a subset).
          Identify the exact failing spec file(s) and run __those__, then a final full run. __Never__ conclude success from a partial run.
          Quote the final summary line of your verification run in your answer.

          When you have completed the task, please provide a summary of what you did and any relevant information that the user should know, including the final summary line of the tests suite.
          This will help ensure that the user understands the changes made and can easily follow up if they have any questions or need further assistance.
        EO_INSTRUCTIONS
      end
    end
  end
end
