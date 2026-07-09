describe XAeonAgents::Cli, '#implement' do
  describe 'testing aspects of the development' do
    before do
      # Stub Launchy.open and $stdin.gets to avoid interactive prompts during plan review
      stub_review_content
      # Override the default stub to return plan_modifications from TesterAgent
      stub_agent_run(
        stub_handler: lambda { |agent, **kwargs|
          case agent
          when XAeonAgents::Agents::PlanGeneratorAgent
            { plan: "Detailed step-by-step plan for requirements \"#{kwargs[:requirements]}\"" }
          when XAeonAgents::Agents::TesterAgent
            { plan_modifications: 'Fix the failing tests' }
          else
            {}
          end
        }
      )
      # Override the test command stub to fail twice, then succeed
      call_count = 0
      stub_command(
        'bundle exec rspec --format documentation',
        stdout: lambda do |_cmd|
          call_count += 1
          call_count <= 2 ? "Test failure ##{call_count}\n" : "All tests passed\n"
        end,
        exit_status: lambda do |_cmd|
          call_count <= 2 ? 1 : 0
        end
      )
    end

    it 'calls TesterAgent repeatedly until tests pass, validating inputs per call' do
      with_git_workspace(files: { 'test.txt' => "original\n" }) do
        base_sha = Git.open(Dir.pwd).gcommit('HEAD').sha
        run_cli 'implement', 'Add a new feature'
        expect(exit_status).to eq 0

        # TesterAgent should have been called exactly 2 times
        tester_run_calls = find_run_calls_for(XAeonAgents::Agents::TesterAgent, all: true)
        expect(tester_run_calls.size).to eq 2

        # ----------------------------------------------------------------------
        # Validate 1st TesterAgent call (after 1st test failure)
        #   The plan is still the original — no revisions have been appended yet.
        # ----------------------------------------------------------------------
        call1 = tester_run_calls[0]
        agent1 = call1[:agent]
        # The expected kwargs that won't change between various tests runs
        common_artifacts = {
          requirements: 'Add a new feature',
          base_sha:,
          tests_cmd: 'bundle exec rspec --format documentation',
          files_diffs: <<~EO_ARTIFACT,
            ### New untracked files



            ### git diff

            ```

            ```
          EO_ARTIFACT
          user_instructions: {
            ordered_list: [
              <<~EO_STEP,
                Understand the initial requirements from the artifact named `#{agent1.artifact_ref(:requirements)}`

                - Understand those requirements and their intent.
              EO_STEP
              <<~EO_STEP,
                Understand the implementation plan from the artifact named `#{agent1.artifact_ref(:plan)}`

                - Understand all the steps of the implementation plan.
              EO_STEP
              <<~EO_STEP,
                Understand the file changes from the artifact named `#{agent1.artifact_ref(:files_diffs)}`

                - Understand what was the intent of the developer implementing the requirements.
              EO_STEP
              <<~EO_STEP,
                Analyze the full output of unit tests run from the artifact named `#{agent1.artifact_ref(:tests_output)}`

                - Check every error reported in the output.
              EO_STEP
              'Fix any issue that unit tests are surfacing, while keeping the original intent of the requirements',
              'Remember any inconsistency and modification you need to make to the implementation plan ' \
                'so that your fixes are in-line with a better implementation plan',
              <<~EO_STEP
                Make sure all tests are running without issue after your fixes

                - You can run tests again using the provided tests command from the artifact named `#{agent1.artifact_ref(:tests_cmd)}` to test your own fixes.
              EO_STEP
            ]
          }
        }
        expect(call1[:kwargs]).to eq(
          **common_artifacts,
          plan: 'Detailed step-by-step plan for requirements "Add a new feature"',
          tests_output: <<~EO_ARTIFACT
            ```
            Test failure #1

            ```
          EO_ARTIFACT
        )

        # ----------------------------------------------------------------------
        # Validate 2nd TesterAgent call (after 2nd test failure)
        #   The plan now includes Revision #0 from the first TesterAgent run.
        # ----------------------------------------------------------------------
        expect(tester_run_calls[1][:kwargs]).to eq(
          **common_artifacts,
          plan: <<~EO_PLAN,
            Detailed step-by-step plan for requirements "Add a new feature"

            # Revision #0 to the implementation plan

            Fix the failing tests

          EO_PLAN
          tests_output: <<~EO_ARTIFACT
            ```
            Test failure #2

            ```
          EO_ARTIFACT
        )

        # Verify the input artifacts received by the DocumenterAgent (with revised plan)
        documenter_run_call = find_run_calls_for(XAeonAgents::Agents::DocumenterAgent)
        expect(documenter_run_call).not_to be_nil
        expect(documenter_run_call[:kwargs][:plan]).to eq(<<~EO_PLAN)
          Detailed step-by-step plan for requirements "Add a new feature"

          # Revision #0 to the implementation plan

          Fix the failing tests

          # Revision #1 to the implementation plan

          Fix the failing tests

        EO_PLAN
      end
    end
  end
end
