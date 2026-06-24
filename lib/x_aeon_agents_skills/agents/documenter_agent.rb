module XAeonAgentsSkills
  module Agents
    # Agent responsible for updating documentation after a new development
    class DocumenterAgent < ComposableAgents::Cline::Agent
      prepend XAeonAgentsSkills::AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          requirements: 'The initial requirements',
          plan: 'Implementation plan that introduced features and fixes to be documented',
          files_diffs: 'Full list of files changes and differences that have been done to implement the initial requirements following the implementation plan'
        }
      end

      # Constructor
      #
      # @param agent_params [Hash<Symbol, Object>] Parameters driving the agent model selection
      def initialize(**agent_params)
        super(
          name: 'Documenter',
          objective: 'Ensure documentation reflects the current product behavior and usage after a new development.',
          constraints: <<~EO_CONSTRAINTS,
            - Only update documentation files.
            - Do NOT change any code or test.
            - NEVER document the fact that a change happened.
            - NEVER explain that something was removed, renamed, or fixed.
            - Documentation describes the CURRENT STATE only.
            - Documentation is NOT a changelog.
          EO_CONSTRAINTS
          skills: %w[
            applying-ruby-conventions
            applying-test-conventions
            updating-doc
            enforcing-project-rules
          ],
          **agent_params
        )
      end
    end
  end
end
