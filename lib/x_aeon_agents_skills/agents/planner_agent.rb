module XAeonAgentsSkills
  module Agents
    # Agent responsible for producing detailed implementation plans from requirements
    class PlannerAgent < ComposableAgents::Cline::Agent
      prepend XAeonAgentsSkills::AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        super.merge(requirements: 'The initial requirements for which you need to devise an implementation plan')
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        super.merge(
          plan: {
            description: "The full and detailed implementation plan in Markdown format, that should implement the requirements given by the artifact named `#{artifact_ref(:requirements)}`",
            type: :markdown
          }
        )
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(
          name: 'Planner',
          role: 'You are a Planner agent',
          objective: 'Produce a full and detailed implementation plan that can be used to implement some requirements.',
          constraints: <<~EO_CONSTRAINTS,
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - You may only analyze and propose plans.
            - Do NOT execute the plan yourself.
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
