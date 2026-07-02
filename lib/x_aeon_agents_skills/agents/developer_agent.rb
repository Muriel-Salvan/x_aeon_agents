require 'diffy'

module XAeonAgentsSkills
  module Agents
    # Agent responsible for developing some requirements
    class DeveloperAgent < ComposableAgents::Agent
      prepend XAeonAgentsSkills::AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        { requirements: 'The initial requirements that need to be implemented' }
      end

      # Constructor
      #
      # @param commit [Boolean] Should we commit files at every step?
      # @param pull_request [Boolean] Should we create a Github Pull Request with this implementation?
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(commit: false, pull_request: false, **agent_params)
        super(name: 'Developer', **agent_params)
        @commit = commit
        @pull_request = pull_request
      end

      # Execute the agent to generate some output artifacts based on some input artifacts.
      #
      # @param requirements [String] Requirements to be implemented
      # @return Hash<Symbol,Object> Output artifacts content
      def run(requirements:)
        # Initial artifacts
        step(:setup_requirements) do
          @artifacts.merge!(
            requirements:,
            base_sha: Helpers.git.gcommit('HEAD').sha
          )
        end

        step_agent(new_agent(PlannerAgent))

        coder_agent = new_agent(CoderAgent, **Models.free_complex)

        step_agent(
          coder_agent,
          user_instructions: "Follow all the steps of the implementation plan described in the artifact named `#{coder_agent.artifact_ref(:plan)}`."
        )
        puts "===== Coder changes: #{Helpers.git.status.changed.keys.join(', ')}"

        step_agent(new_agent(CommitterAgent, user_review: false, stage: :all, authors: [coder_agent])) if @commit

        tester_agent = new_agent(TesterAgent, **Models.free_complex)

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
            step_agent(
              tester_agent,
              user_instructions: {
                ordered_list: [
                  <<~EO_STEP,
                    Understand the initial requirements from the artifact named `#{tester_agent.artifact_ref(:requirements)}`

                    - Understand those requirements and their intent.
                  EO_STEP
                  <<~EO_STEP,
                    Understand the implementation plan from the artifact named `#{tester_agent.artifact_ref(:plan)}`

                    - Understand all the steps of the implementation plan.
                  EO_STEP
                  <<~EO_STEP,
                    Understand the file changes from the artifact named `#{tester_agent.artifact_ref(:files_diffs)}`

                    - Understand what was the intent of the developer implementing the requirements.
                  EO_STEP
                  <<~EO_STEP,
                    Analyze the full output of unit tests run from the artifact named `#{tester_agent.artifact_ref(:tests_output)}`

                    - Check every error reported in the output.
                  EO_STEP
                  'Fix any issue that unit tests are surfacing, while keeping the original intent of the requirements',
                  'Remember any inconsistency and modification you need to make to the implementation plan so that your fixes are in-line with a better implementation plan',
                  <<~EO_STEP
                    Make sure all tests are running without issue after your fixes

                    - You can run tests again using the provided tests command from the artifact named `#{tester_agent.artifact_ref(:tests_cmd)}` to test your own fixes.
                  EO_STEP
                ]
              }
            )
            puts "===== Tester changes: #{Helpers.git.status.changed.keys.join(', ')}"
            # Integrate potential implementation plan modifications
            unless @artifacts[:plan_modifications].strip.empty?
              plan_modifications = @artifacts.delete(:plan_modifications)
              @artifacts[:plan] << <<~EO_PLAN
                # Revision ##{idx_test} to the implementation plan

                #{plan_modifications}

              EO_PLAN
            end
            step_agent(new_agent(CommitterAgent, user_review: false, stage: :all, authors: [tester_agent])) if @commit
            idx_test += 1
          end
        end

        step_agent(new_agent(CommitterAgent, user_review: false, stage: :all, authors: [tester_agent])) if @commit

        documenter_agent = new_agent(DocumenterAgent, **Models.free_complex)
        @artifacts[:files_diffs] = Helpers.artifact_files_diffs(@artifacts[:base_sha])

        step_agent(
          documenter_agent,
          user_instructions: {
            ordered_list: [
              <<~EO_STEP,
                Analyze the initial requirements from the artifact named `#{documenter_agent.artifact_ref(:requirements)}`

                - Those give you information about the requirements you should be documenting.
              EO_STEP
              <<~EO_STEP,
                Analyze all the steps of the implementation plan from the artifact named `#{documenter_agent.artifact_ref(:plan)}`

                - Those give you every step that should have been followed for this new development.
              EO_STEP
              <<~EO_STEP,
                Analyze the concrete changes from the artifact named `#{documenter_agent.artifact_ref(:files_diffs)}`

                - Understand what was the intent of the developer implementing those requirements.
              EO_STEP
              <<~EO_STEP,
                Decide if documentation is needed

                Before making any change, classify the development:

                - If the change affects:
                  - Features
                  - Usage
                  - APIs
                  - Behavior visible to users
                  → Documentation update MAY be required

                - If the change is:
                  - Internal refactor
                  - Cleanup (removal of useless content)
                  - Formatting
                  - Documentation-only removal of irrelevant info
                  → NO documentation update is required

                If no documentation is required:
                → STOP and do nothing
              EO_STEP
              <<~EO_STEP,
                Explore the filesystem to locate documentation files

                Guidelines:
                - Start with README.md and docs/**/*.md if they exist.
                - Look for files mentioning related features or APIs.
                - Find documentation files that are referenced recursively from other documentation files.
                - Understand the documentation structure and content.
                - If no relevant documentation is found, proceed by assuming documentation needs to be created or extended.
                - If you are unsure which documentation file to update: default to updating README.md.

                This step is best-effort and should not block progress.
              EO_STEP
              <<~EO_STEP
                Update the relevant documentation files

                - Only perform this step if you think documentation is required.
                - Use artifacts as the source of truth for understanding the changes to be documented.
                - Use the filesystem to locate where documentation should be updated.
                - After exploring the filesystem, if relevant documentation files are found: update them.

                When updating documentation:
                - Modify existing sections if they already describe related functionality.
                - Add new sections if the feature is not documented.
                - Keep consistency with existing documentation style.
                - Prefer minimal, precise updates over large rewrites.
              EO_STEP
            ]
          }
        )
        puts "===== Documenter changes: #{Helpers.git.status.changed.keys.join(', ')}"

        step_agent(new_agent(CommitterAgent, user_review: false, stage: :all, authors: [documenter_agent])) if @commit

        step_agent(new_agent(PullRequestCreatorAgent, authors: [planner_agent, coder_agent, tester_agent, documenter_agent])) if @pull_request

        puts
        puts 'Requirements implemented successfully'

        @artifacts
      end
    end
  end
end
