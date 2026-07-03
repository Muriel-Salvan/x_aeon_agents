module XAeonAgents
  module Agents
    # Agent responsible for producing an implementation plan acceptable to the user.
    class PlannerAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        super.merge(requirements: 'The initial requirements for which you need to devise an implementation plan')
      end

      # Define output artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        super.merge(
          plan: {
            description: 'The full and detailed implementation plan in Markdown format, ' \
              "that should implement the requirements given by the artifact named `#{artifact_ref(:requirements)}`",
            type: :markdown
          }
        )
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param requirements [String] The initial requirements.
      # @return [Hash{Symbol => Object}] Output artifacts content
      def run(requirements:)
        plan_generator_agent = new_agent(PlanGeneratorAgent, **Models.free_complex_planning)
        user_instructions = {
          ordered_list: [
            "Read the initial requirements from the artifact named `#{plan_generator_agent.artifact_ref(:requirements)}`",
            'Analyze the project files',
            "Create an artifact named `#{plan_generator_agent.artifact_ref(:plan)}` with a complete and detailed " \
            'step-by-step implementation plan in Markdown format'
          ]
        }
        loop do
          step_agent(plan_generator_agent, user_instructions:)
          @artifacts[:plan].strip!
          content, user_prompt = Helpers.review_content(
            session_dir: @session_dir,
            name: 'plan.md',
            description: 'Implementation plan',
            editable: true,
            promptable: true,
            content: @artifacts[:plan]
          )
          diffs = @artifacts[:plan] == content ? nil : Diffy::Diff.new(@artifacts[:plan], content, context: 3, include_diff_info: true).to_s
          @artifacts[:plan] = content
          break if user_prompt.empty?

          user_instructions = <<~EO_INSTRUCTIONS
            #{user_prompt}

            Re-create the artifact named `#{plan_generator_agent.artifact_ref(:plan)}` with a revised implementation plan, taking the above user guidance into account
          EO_INSTRUCTIONS
          user_instructions << <<~EO_INSTRUCTIONS if diffs

            The user performed the following modifications on your implementation plan.
            You have to take them into account while revising the plan.

            ```
            #{
              # Remove the 2 first lines (headers of temporary file names), and last line (missing new line at end of file).
              diffs.to_s.split("\n")[2..-2].join("\n").strip
            }
            ```
          EO_INSTRUCTIONS
        end
        { plan: @artifacts[:plan] }
      end
    end
  end
end
