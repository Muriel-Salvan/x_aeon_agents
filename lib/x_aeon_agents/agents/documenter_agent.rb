module XAeonAgents
  module Agents
    # Agent responsible for updating documentation after a new development
    class DocumenterAgent < ComposableAgents::Cline::Agent
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
            description: 'Implementation plan that introduced features and fixes to be documented',
            type: :markdown
          },
          files_diffs: {
            description: 'Full list of files changes and differences that have been done to implement the initial ' \
              'requirements following the implementation plan',
            type: :text
          }
        )
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(
          name: 'Documenter',
          objective: 'Ensure documentation reflects the current product behavior and usage after a new development.',
          system_instructions: <<~EO_INSTRUCTIONS,
            #{Helpers.repository_access_system_instructions}

            Always gather all the necessary context before starting to work on a task.
            For example, make sure you understand the current behavior of the product by exploring the code, the tests, the existing documentation and the configuration files, so that the documentation you write reflects the current state of the project.
            Begin by analyzing the user's input and gathering any necessary additional context.
            Then, present your plan at the start of your response along with tool calls before proceeding with the task.
            It's OK for this section to be quite long.

            Review each question carefully and answer it with detailed, accurate information.

            If you need more information, use one of the available tools or ask for clarification instead of making assumptions or lies.

            When you have completed the task, please provide a summary of what you did and any relevant information that the user should know.
            This will help ensure that the user understands the changes made and can easily follow up if they have any questions or need further assistance.
          EO_INSTRUCTIONS
          constraints: [
            '- Only update documentation files.',
            '- Do NOT change any code or test.',
            '- NEVER document the fact that a change happened.',
            '- NEVER explain that something was removed, renamed, or fixed.',
            '- Documentation describes the CURRENT STATE only.',
            '- Documentation is NOT a changelog.',
            Helpers.repository_access_constraint(writable: true),
            Helpers.non_interactive_constraint
          ].compact.join("\n"),
          **agent_params
        )
      end
    end
  end
end
