describe XAeonAgents::Cli, '#implement' do
  describe 'pull requests created from the implementation' do
    describe 'simple cases' do
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
        stub_review_content
        stub_command('bundle exec rspec --format documentation', stdout: "All tests passed\n")
        stub_git_diff_interpreter_agent
        mock_github
      end

      it 'creates a pull request' do
        with_git_workspace(
          files: { 'test.txt' => "original\n" },
          branch: 'feature-branch',
          remotes: { 'origin' => 'git@github.com:owner/repo.git' }
        ) do
          base_sha = Git.open(Dir.pwd).gcommit('HEAD').sha
          mock_git_push
          run_cli 'implement', '--pr', 'Add a new feature'
          expect(exit_status).to eq 0

          # Verify commits made (Documenter commits when @pull_request is true)
          git_log = Git.open(Dir.pwd).log.execute
          expect(git_log.count).to eq(2) # Initial + Total commit

          # Most recent commit should be from Documenter
          expect_commit(
            git_log[0],
            <<~EO_COMMIT,
              Mocked 1-line summary of changes from base cached

              Mocked change intent from base git ref cached

              Co-authored by X-Aeon AI Agents:
              * Coder (Cline cline/stepfun/step-3.7-flash)
              * Tester (Cline cline/stepfun/step-3.7-flash)
              * Documenter (Cline cline/stepfun/step-3.7-flash)
              * Diff interpreter (AiAgent openrouter/free)
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
              diff --git a/new_feature.rb b/new_feature.rb
              new file mode git_file_mode
              index git_short_hash..git_short_hash
              --- /dev/null
              +++ b/new_feature.rb
              @@ -0,0 +1 @@
              +puts 'New feature added'
            EO_PATCH
          )

          # Verify the branch was pushed
          expect(git_pushes).to eq [
            {
              url: 'git@github.com:owner/repo.git',
              branch: 'feature-branch',
              options: { force: true }
            }
          ]

          # Verify a PR was created
          expect(github_double).to have_received(:create_pull_request).with(
            'owner/repo',
            base_sha,
            'feature-branch',
            "Mocked 1-line summary of changes from base #{base_sha}",
            <<~EO_DESCRIPTION.chomp
              Mocked change intent from base git ref #{base_sha}

              # Initial requirements given

              Add a new feature

              # Co-authored by X-Aeon AI Agents

              - Planner (Cline cline/stepfun/step-3.7-flash)
              - Coder (Cline cline/stepfun/step-3.7-flash)
              - Tester (Cline cline/stepfun/step-3.7-flash)
              - Documenter (Cline cline/stepfun/step-3.7-flash)
              - Diff interpreter (AiAgent openrouter/free)
            EO_DESCRIPTION
          )
        end
      end

      it 'creates a pull request with commits option' do
        with_git_workspace(
          files: { 'test.txt' => "original\n" },
          branch: 'feature-branch',
          remotes: { 'origin' => 'git@github.com:owner/repo.git' }
        ) do
          base_sha = Git.open(Dir.pwd).gcommit('HEAD').sha
          mock_git_push
          run_cli 'implement', '--pr', '--commit', 'Add a new feature'
          expect(exit_status).to eq 0

          # Verify commits made (Coder commits when @commit is true, Documenter commits when @pull_request or @commit is true)
          git_log = Git.open(Dir.pwd).log.execute
          expect(git_log.count).to eq(3) # Initial + Coder commit + Documenter commit

          # Most recent commit should be from Documenter
          expect_commit(
            git_log[0],
            <<~EO_COMMIT,
              Mocked 1-line summary of changes from base cached

              Mocked change intent from base git ref cached

              Co-authored by X-Aeon AI Agents:
              * Documenter (Cline cline/stepfun/step-3.7-flash)
              * Diff interpreter (AiAgent openrouter/free)
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

          # Second commit should be from Coder
          expect_commit(
            git_log[1],
            <<~EO_COMMIT,
              Mocked 1-line summary of changes from base cached

              Mocked change intent from base git ref cached

              Co-authored by X-Aeon AI Agents:
              * Coder (Cline cline/stepfun/step-3.7-flash)
              * Diff interpreter (AiAgent openrouter/free)
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

          # Oldest commit should be the initial commit
          expect(git_log[2].message.strip).to eq('Initial commit')

          # Verify the branch was pushed
          expect(git_pushes).to eq [
            {
              url: 'git@github.com:owner/repo.git',
              branch: 'feature-branch',
              options: { force: true }
            }
          ]

          # Verify a PR was created (same as without the --commit option)
          expect(github_double).to have_received(:create_pull_request).with(
            'owner/repo',
            base_sha,
            'feature-branch',
            "Mocked 1-line summary of changes from base #{base_sha}",
            <<~EO_DESCRIPTION.chomp
              Mocked change intent from base git ref #{base_sha}

              # Initial requirements given

              Add a new feature

              # Co-authored by X-Aeon AI Agents

              - Planner (Cline cline/stepfun/step-3.7-flash)
              - Coder (Cline cline/stepfun/step-3.7-flash)
              - Tester (Cline cline/stepfun/step-3.7-flash)
              - Documenter (Cline cline/stepfun/step-3.7-flash)
              - Diff interpreter (AiAgent openrouter/free)
            EO_DESCRIPTION
          )
        end
      end
    end

    describe 'validating user plan revisions in the PR description' do
      before do
        # Stub agent runs, counting plan revisions driven by user feedback during plan review.
        # The PlanGeneratorAgent is re-run once per user revision, so a counter lets us
        # produce a distinct final plan (v3) that flows into the downstream agents.
        plan_version = 0
        stub_agent_run(
          stub_handler: lambda { |agent, **kwargs|
            case agent
            when XAeonAgents::Agents::PlanGeneratorAgent
              plan_version += 1
              agent.track_message(message: agent.render_instructions(kwargs[:user_instructions]), author: 'user')
              agent.track_message(message: "I devised a new plan (v#{plan_version})", author: 'assistant')
              { plan: "Detailed step-by-step plan (v#{plan_version}) for requirements \"#{kwargs[:requirements]}\"" }
            when XAeonAgents::Agents::TesterAgent
              { plan_modifications: '' }
            when XAeonAgents::Agents::CoderAgent
              agent.track_message(message: 'Which file name should I use?', author: 'assistant', question: true)
              agent.track_message(message: 'new_feature.rb', author: 'user')
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
        # User reviews the plan and gives 2 rounds of feedback before accepting (empty prompt).
        stub_review_content(stdin_response: ['Please add logging', 'Please add tests', ''])
        stub_command('bundle exec rspec --format documentation', stdout: "All tests passed\n")
        stub_git_diff_interpreter_agent
        mock_github
      end

      it 'creates a PR with the final revised plan after the user gives 2 plan revisions' do
        with_git_workspace(
          files: { 'test.txt' => "original\n" },
          branch: 'feature-branch',
          remotes: { 'origin' => 'git@github.com:owner/repo.git' }
        ) do
          base_sha = Git.open(Dir.pwd).gcommit('HEAD').sha
          mock_git_push
          run_cli 'implement', '--pr', 'Add a new feature'
          expect(exit_status).to eq 0

          # PlanGeneratorAgent should have run 3 times: initial plan + 2 user revisions.
          plan_calls = find_run_calls_for(XAeonAgents::Agents::PlanGeneratorAgent, all: true)
          expect(plan_calls.size).to eq 3
          plan_generator_agent = plan_calls.first[:agent]

          # The user revision prompts are forwarded to the PlanGeneratorAgent on the 2nd and 3rd calls.
          expect(plan_calls[1][:kwargs][:user_instructions]).to include('Please add logging')
          expect(plan_calls[2][:kwargs][:user_instructions]).to include('Please add tests')

          # The final (accepted) plan is v3 and flows to Coder and Documenter.
          # (TesterAgent is not run here because the tests pass on the first try.)
          final_plan = 'Detailed step-by-step plan (v3) for requirements "Add a new feature"'
          expect(find_run_calls_for(XAeonAgents::Agents::CoderAgent)[:kwargs][:plan]).to eq final_plan
          expect(find_run_calls_for(XAeonAgents::Agents::DocumenterAgent)[:kwargs][:plan]).to eq final_plan

          # Verify commits made (Documenter commits when @pull_request is true)
          git_log = Git.open(Dir.pwd).log.execute
          expect(git_log.count).to eq(2) # Initial + Total commit

          # Most recent commit should be from Documenter (with Coder + Tester + Documenter as authors)
          expect_commit(
            git_log[0],
            <<~EO_COMMIT,
              Mocked 1-line summary of changes from base cached

              Mocked change intent from base git ref cached

              Co-authored by X-Aeon AI Agents:
              * Coder (Cline cline/stepfun/step-3.7-flash)
              * Tester (Cline cline/stepfun/step-3.7-flash)
              * Documenter (Cline cline/stepfun/step-3.7-flash)
              * Diff interpreter (AiAgent openrouter/free)
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
              diff --git a/new_feature.rb b/new_feature.rb
              new file mode git_file_mode
              index git_short_hash..git_short_hash
              --- /dev/null
              +++ b/new_feature.rb
              @@ -0,0 +1 @@
              +puts 'New feature added'
            EO_PATCH
          )

          # Verify the branch was pushed
          expect(git_pushes).to eq [
            {
              url: 'git@github.com:owner/repo.git',
              branch: 'feature-branch',
              options: { force: true }
            }
          ]

          # Verify a PR was created with the final revised plan.
          expect(github_double).to have_received(:create_pull_request).with(
            'owner/repo',
            base_sha,
            'feature-branch',
            "Mocked 1-line summary of changes from base #{base_sha}",
            an_object_satisfying { |actual|
              # The description embeds run-time timestamps (<sub>...</sub>) that vary, so
              # normalize them to <sub>timestamp</sub> before comparing.
              actual.gsub(%r{<sub>.+</sub>}, '<sub>timestamp</sub>') == <<~EO_DESCRIPTION.chomp
                Mocked change intent from base git ref #{base_sha}

                # Initial requirements given

                Add a new feature

                # User guidance and feedback to agents

                › **user**
                > Please add logging
                >
                > Re-create the artifact named `#{plan_generator_agent.artifact_ref(:plan)}` with a revised implementation plan, taking the above user guidance into account
                > <sub>timestamp</sub>

                › **user**
                > Please add tests
                >
                > Re-create the artifact named `#{plan_generator_agent.artifact_ref(:plan)}` with a revised implementation plan, taking the above user guidance into account
                > <sub>timestamp</sub>

                › **assistant**
                > Which file name should I use?
                > <sub>timestamp</sub>
                >
                > › **user**
                > &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;new_feature.rb
                > &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<sub>timestamp</sub>

                # Co-authored by X-Aeon AI Agents

                - Planner (Cline cline/stepfun/step-3.7-flash)
                - Coder (Cline cline/stepfun/step-3.7-flash)
                - Tester (Cline cline/stepfun/step-3.7-flash)
                - Documenter (Cline cline/stepfun/step-3.7-flash)
                - Diff interpreter (AiAgent openrouter/free)
              EO_DESCRIPTION
            }
          )
        end
      end
    end
  end
end
