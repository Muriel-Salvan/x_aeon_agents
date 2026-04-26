module XAeonAgentsSkills
  module Agents
    # Agent responsible for developing some requirements
    class DeveloperAgent < ComposableAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract
      prepend ComposableAgents::Mixins::Resumable

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          requirements: 'Initial requirements that need to be implemented'
        }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {}
      end

      # Constructor
      #
      # @param commit [Boolean] Should we commit files at every step?
      # @param pull_request [Boolean] Should we create a Github Pull Request with this implementation?
      # @param kwargs [Hash<Symbol, Object>] Agent parameters
      def initialize(commit: false, pull_request: false, **kwargs)
        super(name: 'Developer', **kwargs)
        @commit = commit
        @pull_request = pull_request
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param requirements [String] Requirements to be implemented
      # @param input_artifacts [Hash<Symbol,Object>] The input artifacts content
      # @return Hash<Symbol,Object> Output artifacts content
      def run(requirements:, **_input_artifacts)
        # Initial artifacts
        step(:setup_requirements) do
          @artifacts.merge!(
            requirements:,
            base_sha: Helpers.git.gcommit('HEAD').sha
          )
        end

        # planner_agent = PlannerAgent.new(**Models.free_complex_planning)
        planner_agent = PlannerAgent.new(**Models.free_simple)

        step(:plan) do
          loop do
            step_agent(planner_agent)
            content, user_prompt = Helpers.review_content(
              name: 'plan.md',
              description: 'Implementation plan',
              editable: true,
              promptable: true,
              content: @artifacts[:plan]
            )
            @artifacts[:plan] = content
            @artifacts[:user_message] = user_prompt
            break if user_prompt.empty?
          end
        end

        coder_agent = CoderAgent.new(**Models.free_simple)

        step_agent(coder_agent)
        puts "===== Coder changes: #{Helpers.git.status.changed.keys.join(', ')}"

        step_agent(CommitterAgent.new(user_review: false, stage: :all, authors: [coder_agent])) if @commit

        tester_agent = TesterAgent.new(**Models.free_simple)

        step(:test) do
          tests_cmd = 'bundle exec rspec --format documentation'
          @artifacts[:tests_cmd] = tests_cmd
          idx_test = 0
          loop do
            puts
            puts "===== Run tests ##{idx_test}..."
            test_result = Helpers.run_cmd(tests_cmd, expected_exit_status: nil)
            puts "Tests ##{idx_test} exit status: #{test_result[:exit_status]}"
            @artifacts[:tests_output] = <<~EO_ARTIFACT
              ```
              #{test_result[:stdout]}
              ```
            EO_ARTIFACT
            break if test_result[:exit_status].zero?

            @artifacts[:files_diffs] = Helpers.artifact_files_diffs(@artifacts[:base_sha])
            step_agent(tester_agent)
            puts "===== Tester changes: #{Helpers.git.status.changed.keys.join(', ')}"
            # Integrate potential implementation plan modifications
            unless @artifacts[:plan_modifications].strip.empty?
              plan_modifications = @artifacts.delete(:plan_modifications)
              @artifacts[:plan] << <<~EO_PLAN
                # Revision ##{idx_test} to the implementation plan

                #{plan_modifications}

              EO_PLAN
            end
            step_agent(CommitterAgent.new(user_review: false, stage: :all, authors: [tester_agent])) if @commit
            idx_test += 1
          end
        end

        step_agent(CommitterAgent.new(user_review: false, stage: :all, authors: [tester_agent])) if @commit

        documenter_agent = DocumenterAgent.new(**Models.free_simple)
        @artifacts[:files_diffs] = Helpers.artifact_files_diffs(@artifacts[:base_sha])

        step_agent(documenter_agent)
        puts "===== Documenter changes: #{Helpers.git.status.changed.keys.join(', ')}"

        step_agent(CommitterAgent.new(user_review: false, stage: :all, authors: [documenter_agent])) if @commit

        step_agent(PullRequestCreatorAgent.new(authors: [planner_agent, coder_agent, tester_agent, documenter_agent])) if @pull_request

        puts
        puts 'Requirements implemented successfully'
      end
    end
  end
end
