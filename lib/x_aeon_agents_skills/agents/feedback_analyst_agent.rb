module XAeonAgentsSkills
  module Agents
    # Agent responsible for extracting requirements from PR comments directed at X-Aeon Agents
    class FeedbackAnalystAgent < ComposableAgents::Cline::Agent
      prepend XAeonAgentsSkills::AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        super.merge(
          pr_description: 'The Pull Request description (context)',
          pr_files_diffs: 'The files modifications that were done in this Pull Request (context)',
          conversations: 'All Pull Request conversations and comments to be considered (context)',
          open_comments_to_agents: 'The exact list of agent-directed comments that need to be addressed'
        )
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        super.merge(
          requirements: {
            description: 'The requirements that will implement what is needed by the agent-directed comments (reply "No requirements" if there is no implementation needed)',
            type: :markdown
          }
        )
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(
          name: 'FeedbackAnalyst',
          role: 'You are a feedback analyst agent, analyzing feedback from a Pull Request and devising new requirements to address this feedback.',
          objective: 'Extract requirements from Pull Request comments',
          constraints: <<~EO_CONSTRAINTS,
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - Focus only on agent-directed comments (/agent) for requirement extraction.
            - Output clear, actionable requirements or "No requirements" if none exist.
          EO_CONSTRAINTS
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            enforcing-project-rules
          ],
          **agent_params
        )
      end
    end
  end
end
