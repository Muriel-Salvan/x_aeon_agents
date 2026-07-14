require 'git'

describe XAeonAgents::Cli, '#implement' do
  describe 'commits steps of the development' do
    context 'when tests pass on the first try' do
      before do
        # Stub all ComposableAgents::Cline::Agent and ComposableAgents::AiAgents::Agent subclasses.
        # These handle the actual agent runs (PlanGeneratorAgent, CoderAgent, TesterAgent, DocumenterAgent).
        stub_agent_run(
          stub_handler: lambda { |agent, **kwargs|
            case agent
            when XAeonAgents::Agents::PlanGeneratorAgent
              { plan: "Detailed step-by-step plan for requirements \"#{kwargs[:requirements]}\"" }
            when XAeonAgents::Agents::TesterAgent
              { plan_modifications: '' }
            when XAeonAgents::Agents::CoderAgent
              # Simulate a file modification done by the coder
              File.write('new_feature.rb', "puts 'New feature added'\n")
              {}
            when XAeonAgents::Agents::DocumenterAgent
              # Simulate a README creation done by the documenter
              File.write('README.md', "# Test Project\n\nThis is a test project.\n")
              {}
            else
              {}
            end
          }
        )
        # Stub Launchy.open and $stdin.gets to avoid interactive prompts during plan review
        stub_review_content
        # Stub the test run command to return success on first try, so TesterAgent is not called.
        stub_command('bundle exec rspec --format documentation', stdout: "All tests passed\n")
        # Stub GitDiffInterpreterAgent to avoid AI calls during commits.
        # The run method outputs the 2 needed artifacts (one_line_summary, change_intent)
        # using the content of the input artifacts (the actual git cached diff).
        agent = instance_double(XAeonAgents::Agents::GitDiffInterpreterAgent)
        allow(agent).to receive(:run) do |git_ref_base:|
          {
            one_line_summary: "1-line summary of diff from #{git_ref_base}",
            change_intent: "Change intent of the diff from #{git_ref_base}"
          }
        end
        allow(agent).to receive(:diff_interpreter_agent) do
          instance_double(XAeonAgents::Agents::DiffInterpreterAgent, full_name: 'Test Agent')
        end
        allow(XAeonAgents::Agents::GitDiffInterpreterAgent).to receive(:new).and_return(agent)
      end

      it 'creates commits for coder and documenter steps' do
        with_git_workspace(files: { 'test.txt' => "original\n" }) do
          run_cli 'implement', '--commit', 'Add a new feature'
          expect(exit_status).to eq 0

          git_log = Git.open(Dir.pwd).log.execute
          expect(git_log.count).to eq(3)

          # Most recent commit: Documenter
          expect_commit(
            git_log[0],
            <<~EO_COMMIT,
              1-line summary of diff from cached

              Change intent of the diff from cached

              Co-authored by X-Aeon AI Agents:
              * Documenter (Cline cline/test-free-complex-model)
              * Test Agent
            EO_COMMIT
            <<~EO_PATCH
              diff --git a/README.md b/README.md
              new file mode git_file_mode
              index git_short_hash..git_short_hash
              --- /dev/null
              +++ b/README.md
              @@ -0,0 +1,3 @@
              +# Test Project
              +
              +This is a test project.
            EO_PATCH
          )

          # Second commit: Coder
          expect_commit(
            git_log[1],
            <<~EO_COMMIT,
              1-line summary of diff from cached

              Change intent of the diff from cached

              Co-authored by X-Aeon AI Agents:
              * Coder (Cline cline/test-free-complex-model)
              * Test Agent
            EO_COMMIT
            <<~EO_PATCH
              diff --git a/new_feature.rb b/new_feature.rb
              new file mode git_file_mode
              index git_short_hash..git_short_hash
              --- /dev/null
              +++ b/new_feature.rb
              @@ -0,0 +1 @@
              +puts 'New feature added'
            EO_PATCH
          )

          # Oldest commit: Initial commit
          expect(git_log[2].message.strip).to eq('Initial commit')
        end
      end
    end

    context 'when tests fail twice before passing' do
      before do
        # Stub Launchy.open and $stdin.gets to avoid interactive prompts during plan review
        stub_review_content
        # Override the default stub to return plan_modifications from TesterAgent.
        # A revision counter increments on each call and is embedded in both the
        # file content and the plan_modifications so that each call produces a unique diff.
        tester_revision = 0
        stub_agent_run(
          stub_handler: lambda { |agent, **kwargs|
            case agent
            when XAeonAgents::Agents::PlanGeneratorAgent
              { plan: "Detailed step-by-step plan for requirements \"#{kwargs[:requirements]}\"" }
            when XAeonAgents::Agents::TesterAgent
              tester_revision += 1
              File.write('test.rb', "puts 'Fixed test revision #{tester_revision}'\n")
              { plan_modifications: "Fix the failing tests (revision #{tester_revision})" }
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
        # Stub GitDiffInterpreterAgent to avoid AI calls during commits
        agent = instance_double(XAeonAgents::Agents::GitDiffInterpreterAgent)
        allow(agent).to receive(:run) do |git_ref_base:|
          {
            one_line_summary: "1-line summary of diff from #{git_ref_base}",
            change_intent: "Change intent of the diff from #{git_ref_base}"
          }
        end
        allow(agent).to receive(:diff_interpreter_agent) do
          instance_double(XAeonAgents::Agents::DiffInterpreterAgent, full_name: 'Test Agent')
        end
        allow(XAeonAgents::Agents::GitDiffInterpreterAgent).to receive(:new).and_return(agent)
      end

      it 'creates a commit for each tester fix revision' do
        with_git_workspace(files: { 'test.txt' => "original\n" }) do
          run_cli 'implement', '--commit', 'Add a new feature'
          expect(exit_status).to eq 0

          git_log = Git.open(Dir.pwd).log.execute
          # Initial commit + 2 tester commits (each revision produces a unique diff)
          expect(git_log.count).to eq(3)

          # Most recent commit: Tester revision 2
          expect_commit(
            git_log[0],
            <<~EO_COMMIT,
              1-line summary of diff from cached

              Change intent of the diff from cached

              Co-authored by X-Aeon AI Agents:
              * Tester (Cline cline/test-free-complex-model)
              * Test Agent
            EO_COMMIT
            <<~EO_PATCH
              diff --git a/test.rb b/test.rb
              index git_short_hash..git_short_hash git_file_mode
              --- a/test.rb
              +++ b/test.rb
              @@ -1 +1 @@
              -puts 'Fixed test revision 1'
              +puts 'Fixed test revision 2'
            EO_PATCH
          )

          # Second commit: Tester revision 1 (new file)
          expect_commit(
            git_log[1],
            <<~EO_COMMIT,
              1-line summary of diff from cached

              Change intent of the diff from cached

              Co-authored by X-Aeon AI Agents:
              * Tester (Cline cline/test-free-complex-model)
              * Test Agent
            EO_COMMIT
            <<~EO_PATCH
              diff --git a/test.rb b/test.rb
              new file mode git_file_mode
              index git_short_hash..git_short_hash
              --- /dev/null
              +++ b/test.rb
              @@ -0,0 +1 @@
              +puts 'Fixed test revision 1'
            EO_PATCH
          )

          # Oldest commit: Initial commit
          expect(git_log[2].message.strip).to eq('Initial commit')
        end
      end
    end
  end
end
