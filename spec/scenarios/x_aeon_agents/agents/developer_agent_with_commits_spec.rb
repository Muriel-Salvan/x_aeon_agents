require 'git'

describe XAeonAgents::Agents::DeveloperAgent do
  describe 'commits steps of the development' do
    context 'when no tests command is configured' do
      before do
        # Stub all ComposableAgents::Cline::Agent and ComposableAgents::AiAgents::Agent subclasses.
        # These handle the actual agent runs (PlanGeneratorAgent, CoderAgent, DocumenterAgent).
        # Also stub GitDiffInterpreterAgent (inherits from ComposableAgents::Agent directly, not covered by the prepend).
        stub_agent_run(
          agent_classes: [XAeonAgents::Agents::GitDiffInterpreterAgent],
          stub_handler: lambda { |agent, **kwargs|
            case agent
            when XAeonAgents::Agents::PlanGeneratorAgent
              { plan: "Detailed step-by-step plan for requirements \"#{kwargs[:requirements]}\"" }
            when XAeonAgents::Agents::CoderAgent
              # Simulate a file modification done by the coder
              File.write('new_feature.rb', "puts 'New feature added'\n")
              {}
            when XAeonAgents::Agents::DocumenterAgent
              # Simulate a README creation done by the documenter
              File.write('README.md', "# Test Project\n\nThis is a test project.\n")
              {}
            when XAeonAgents::Agents::GitDiffInterpreterAgent
              {
                one_line_summary: "1-line summary of diff from #{kwargs[:git_ref_base]}",
                change_intent: "Change intent of the diff from #{kwargs[:git_ref_base]}"
              }
            else
              {}
            end
          },
          agent_stub_block: lambda { |agent|
            allow(agent).to receive(:diff_interpreter_agent) do
              instance_double(XAeonAgents::Agents::DiffInterpreterAgent, full_name: 'Test Agent')
            end
          }
        )
        # Stub Launchy.open and $stdin.gets to avoid interactive prompts during plan review
        stub_review_content
      end

      it 'creates commits for coder and documenter steps' do
        with_git_workspace(files: { 'test.txt' => "original\n" }) do
          described_class.new(session_id: nil, commit: true, pull_request: false).run(requirements: 'Add a new feature')

          git_log = Git.open(Dir.pwd).log.execute
          expect(git_log.count).to eq(3)

          # Most recent commit: Documenter
          expect_commit(
            git_log[0],
            <<~EO_COMMIT,
              1-line summary of diff from cached

              Change intent of the diff from cached

              Co-authored by X-Aeon AI Agents:
              * Documenter (Cline cline/anthropic/claude-sonnet-4.6)
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
              * Coder (Cline cline/anthropic/claude-sonnet-4.6)
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
        # Isolate the configuration loading from any real user configuration file
        allow(Dir).to receive(:home).and_return(temp_dir('home'))
        # Override the default stub to return plan_modifications from TesterAgent.
        # A revision counter increments on each call and is embedded in both the
        # file content and the plan_modifications so that each call produces a unique diff.
        tester_revision = 0
        # Also stub GitDiffInterpreterAgent (inherits from ComposableAgents::Agent directly, not covered by the prepend).
        stub_agent_run(
          agent_classes: [XAeonAgents::Agents::GitDiffInterpreterAgent],
          stub_handler: lambda { |agent, **kwargs|
            case agent
            when XAeonAgents::Agents::PlanGeneratorAgent
              { plan: "Detailed step-by-step plan for requirements \"#{kwargs[:requirements]}\"" }
            when XAeonAgents::Agents::TesterAgent
              tester_revision += 1
              File.write('test.rb', "puts 'Fixed test revision #{tester_revision}'\n")
              { plan_modifications: "Fix the failing tests (revision #{tester_revision})" }
            when XAeonAgents::Agents::GitDiffInterpreterAgent
              {
                one_line_summary: "1-line summary of diff from #{kwargs[:git_ref_base]}",
                change_intent: "Change intent of the diff from #{kwargs[:git_ref_base]}"
              }
            else
              {}
            end
          },
          agent_stub_block: lambda { |agent|
            allow(agent).to receive(:diff_interpreter_agent) do
              instance_double(XAeonAgents::Agents::DiffInterpreterAgent, full_name: 'Test Agent')
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

      it 'creates a commit for each tester fix revision' do
        with_git_workspace(
          files: {
            'test.txt' => "original\n",
            '.x_aeon_agents.rb' => "test_project_cmd 'bundle exec rspec --format documentation'\n"
          }
        ) do
          # Load the config file, like the CLI does before running the agent
          XAeonAgents::Config.load
          described_class.new(session_id: nil, commit: true, pull_request: false).run(requirements: 'Add a new feature')

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
              * Tester (Cline cline/anthropic/claude-sonnet-4.6)
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
              * Tester (Cline cline/anthropic/claude-sonnet-4.6)
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
