module XAeonAgents
  module Agents
    # Agent responsible for extracting requirements from PR comments directed at X-Aeon Agents
    class FeedbackAnalystAgent < ComposableAgents::Cline::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        super.merge(
          pr_description: {
            description: 'The Pull Request description (context)',
            type: :markdown
          },
          pr_files_diffs: {
            description: 'The files modifications that were done in this Pull Request (context)',
            type: :text
          },
          conversations: {
            description: 'All Pull Request conversations and comments to be considered (context)',
            type: :json
          },
          open_comments_to_agents: {
            description: 'The exact list of agent-directed comments that need to be addressed',
            type: :json
          }
        )
      end

      # Define output artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        super.merge(
          requirements: {
            description: 'The requirements that will implement what is needed by the agent-directed comments ' \
              '(reply "No requirements" if there is no implementation needed)',
            type: :markdown
          }
        )
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(
          name: 'Feedback analyst',
          role: 'You are a feedback analyst agent, analyzing feedback from a Pull Request and devising new requirements to address this feedback.',
          objective: 'Extract requirements from Pull Request comments',
          system_instructions: <<~EO_INSTRUCTIONS,
            #{Helpers.repository_access_system_instructions}

            Always gather all the necessary context before starting to work on a task: read the Pull Request description, files diffs and conversations, and explore the repository's code when needed.
            Begin by analyzing the user's input and gathering any necessary additional context.
            Review each question carefully and answer it with detailed, accurate information.
            If you need more information, use one of the available tools or ask for clarification instead of making assumptions or lies.
            Do not indicate that you will perform an action without actually doing it.
          EO_INSTRUCTIONS
          **agent_params
        )
        self.constraints = [
          '- You are in read-only mode for the repository: do NOT modify any file of it.',
          '- Focus only on agent-directed comments (/agent) for requirement extraction.',
          '- Write the extracted requirements to the output artifact file given in this prompt.',
          '- If no implementation is required, write exactly `No requirements` in this file.',
          Helpers.repository_access_constraint,
          Helpers.cline_tools_constraint,
          Helpers.artifacts_access_constraint(artifact_ref(:requirements)),
          Helpers.non_interactive_constraint
        ].compact.join("\n")
      end
    end
  end
end
