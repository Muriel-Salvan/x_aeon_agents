describe XAeonAgents::Cli, '#implement' do
  describe 'user reviewing implementation plan' do
    before do
      # Stub all ComposableAgents::Cline::Agent and ComposableAgents::AiAgents::Agent subclasses.
      # These handle the actual agent runs (PlanGeneratorAgent, CoderAgent, TesterAgent, DocumenterAgent).
      plan_version = 0
      stub_agent_run(
        stub_handler: lambda { |agent, **kwargs|
          case agent
          when XAeonAgents::Agents::PlanGeneratorAgent
            plan_version += 1
            { plan: "Detailed step-by-step plan (v#{plan_version}) for requirements \"#{kwargs[:requirements]}\"\n" }
          when XAeonAgents::Agents::TesterAgent
            { plan_modifications: 'Fix the failing tests' }
          else
            {}
          end
        }
      )
      # Stub the test run command to fail once, then succeed (so TesterAgent is called once)
      call_count = 0
      stub_command(
        'bundle exec rspec --format documentation',
        stdout: lambda do |_cmd|
          call_count += 1
          call_count <= 1 ? "Test failure #1\n" : "All tests passed\n"
        end,
        exit_status: lambda do |_cmd|
          call_count <= 1 ? 1 : 0
        end
      )
    end

    it 'calls PlanGeneratorAgent multiple times when user gives feedback, validates inputs per call, and uses accepted plan for downstream agents' do
      stub_review_content(stdin_response: ['Please add more details to the plan', ''])
      with_git_workspace(files: { 'test.txt' => "original\n" }) do
        run_cli 'implement', 'Add a new feature'
        expect(exit_status).to eq 0

        # PlanGeneratorAgent should have been called exactly 2 times (initial + after user feedback)
        plan_calls = find_run_calls_for(XAeonAgents::Agents::PlanGeneratorAgent, all: true)
        expect(plan_calls.size).to eq 2

        # ----------------------------------------------------------------------
        # Validate 1st PlanGeneratorAgent call (initial plan generation)
        # ----------------------------------------------------------------------
        call1 = plan_calls[0]
        agent1 = call1[:agent]
        expect(call1[:kwargs]).to eq(
          requirements: 'Add a new feature',
          user_instructions: {
            ordered_list: [
              "Read the initial requirements from the artifact named `#{agent1.artifact_ref(:requirements)}`",
              'Analyze the project files',
              "Create an artifact named `#{agent1.artifact_ref(:plan)}` with a complete and detailed " \
                'step-by-step implementation plan in Markdown format'
            ]
          }
        )

        # ----------------------------------------------------------------------
        # Validate 2nd PlanGeneratorAgent call (with user feedback, no diffs since file was not edited)
        #   The plan artifact is now passed along (from the first PlanGeneratorAgent's output)
        # ----------------------------------------------------------------------
        call2 = plan_calls[1]
        agent2 = call2[:agent]
        # The same agent should work on the feedback
        expect(agent2).to eq agent1
        expect(call2[:kwargs]).to eq(
          requirements: 'Add a new feature',
          user_instructions: <<~EO_INSTRUCTIONS
            Please add more details to the plan

            Re-create the artifact named `#{agent2.artifact_ref(:plan)}` with a revised implementation plan, taking the above user guidance into account.
          EO_INSTRUCTIONS
        )

        # Validate CoderAgent, TesterAgent, and DocumenterAgent all receive the
        # plan from the last (accepted) PlanGeneratorAgent call
        final_plan = 'Detailed step-by-step plan (v2) for requirements "Add a new feature"'
        expect(find_run_calls_for(XAeonAgents::Agents::CoderAgent)[:kwargs][:plan]).to eq final_plan
        expect(find_run_calls_for(XAeonAgents::Agents::TesterAgent)[:kwargs][:plan]).to eq final_plan
        expect(find_run_calls_for(XAeonAgents::Agents::DocumenterAgent)[:kwargs][:plan]).to eq <<~EO_PLAN
          #{final_plan}

          # Revision #0 to the implementation plan

          Fix the failing tests

        EO_PLAN
      end
    end

    it 'uses user-modified plan directly when user edits file and accepts immediately, without calling PlanGeneratorAgent again' do
      stub_review_content(stdin_response: '') do |file_path|
        # Simulate user editing the plan file before accepting
        File.write(file_path, "# User Modified Plan\n\nThis was edited by the user.")
      end
      with_git_workspace(files: { 'test.txt' => "original\n" }) do
        run_cli 'implement', 'Add a new feature'
        expect(exit_status).to eq 0

        # PlanGeneratorAgent should have been called exactly 1 time (only initial generation)
        plan_calls = find_run_calls_for(XAeonAgents::Agents::PlanGeneratorAgent, all: true)
        expect(plan_calls.size).to eq 1

        # Validate the 1st (and only) PlanGeneratorAgent call
        call1 = plan_calls[0]
        agent1 = call1[:agent]
        expect(call1[:kwargs]).to eq(
          requirements: 'Add a new feature',
          user_instructions: {
            ordered_list: [
              "Read the initial requirements from the artifact named `#{agent1.artifact_ref(:requirements)}`",
              'Analyze the project files',
              "Create an artifact named `#{agent1.artifact_ref(:plan)}` with a complete and detailed " \
                'step-by-step implementation plan in Markdown format'
            ]
          }
        )

        # The accepted plan is the user-modified version (not what PlanGeneratorAgent returned)
        user_plan = "# User Modified Plan\n\nThis was edited by the user."
        expect(find_run_calls_for(XAeonAgents::Agents::CoderAgent)[:kwargs][:plan]).to eq user_plan
        expect(find_run_calls_for(XAeonAgents::Agents::TesterAgent)[:kwargs][:plan]).to eq user_plan
        expect(find_run_calls_for(XAeonAgents::Agents::DocumenterAgent)[:kwargs][:plan]).to eq <<~EO_PLAN
          #{user_plan}

          # Revision #0 to the implementation plan

          Fix the failing tests

        EO_PLAN
      end
    end

    it 'calls PlanGeneratorAgent multiple times when user gives feedback and edits plan file, validating inputs and final plan' do
      edit_version = 0
      stub_review_content(stdin_response: ['Please revise', '']) do |file_path|
        # Simulate user editing the plan file before giving feedback
        edit_version += 1
        File.write(file_path, "# Revised Plan (v#{edit_version})\n\nUpdated by user before feedback.\n")
      end
      with_git_workspace(files: { 'test.txt' => "original\n" }) do
        run_cli 'implement', 'Add a new feature'
        expect(exit_status).to eq 0

        # PlanGeneratorAgent should have been called exactly 2 times (initial + after feedback with diffs)
        plan_calls = find_run_calls_for(XAeonAgents::Agents::PlanGeneratorAgent, all: true)
        expect(plan_calls.size).to eq 2

        # ----------------------------------------------------------------------
        # Validate 1st PlanGeneratorAgent call (initial plan generation)
        # ----------------------------------------------------------------------
        call1 = plan_calls[0]
        agent1 = call1[:agent]
        expect(call1[:kwargs]).to eq(
          requirements: 'Add a new feature',
          user_instructions: {
            ordered_list: [
              "Read the initial requirements from the artifact named `#{agent1.artifact_ref(:requirements)}`",
              'Analyze the project files',
              "Create an artifact named `#{agent1.artifact_ref(:plan)}` with a complete and detailed " \
                'step-by-step implementation plan in Markdown format'
            ]
          }
        )

        # ----------------------------------------------------------------------
        # Validate 2nd PlanGeneratorAgent call (with user feedback and diffs from file edits)
        # ----------------------------------------------------------------------
        call2 = plan_calls[1]
        agent2 = call2[:agent]
        # The same agent should work on the feedback
        expect(agent2).to eq agent1
        expect(call2[:kwargs]).to eq(
          requirements: 'Add a new feature',
          user_instructions: <<~EO_INSTRUCTIONS
            Please revise

            Re-create the artifact named `#{agent2.artifact_ref(:plan)}` with a revised implementation plan, taking the above user guidance into account.

            The user performed the following modifications on your implementation plan.
            You have to take them into account while revising the plan.

            ```
            @@ -1 +1,3 @@
            -Detailed step-by-step plan (v1) for requirements "Add a new feature"
            +# Revised Plan (v1)
            +
            +Updated by user before feedback.
            ```
          EO_INSTRUCTIONS
        )

        # Validate CoderAgent, TesterAgent, and DocumenterAgent all receive the
        # plan from the last (accepted) iteration — which includes user's final edits
        final_plan = "# Revised Plan (v2)\n\nUpdated by user before feedback."
        expect(find_run_calls_for(XAeonAgents::Agents::CoderAgent)[:kwargs][:plan]).to eq final_plan
        expect(find_run_calls_for(XAeonAgents::Agents::TesterAgent)[:kwargs][:plan]).to eq final_plan
        expect(find_run_calls_for(XAeonAgents::Agents::DocumenterAgent)[:kwargs][:plan]).to eq <<~EO_PLAN
          #{final_plan}

          # Revision #0 to the implementation plan

          Fix the failing tests

        EO_PLAN
      end
    end
  end
end
