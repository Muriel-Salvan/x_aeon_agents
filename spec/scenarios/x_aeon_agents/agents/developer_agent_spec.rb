require_relative 'shared_examples/common_behavior'

describe XAeonAgents::Agents::DeveloperAgent do
  before do
    stub_agent_run(
      stub_handler: lambda { |agent, **kwargs|
        case agent
        when XAeonAgents::Agents::PlanGeneratorAgent
          { plan: "Detailed step-by-step plan for requirements \"#{kwargs[:requirements]}\"" }
        when XAeonAgents::Agents::CoderAgent
          File.write('new_feature.rb', <<~RUBY)
            puts 'New feature added'
          RUBY
          {}
        when XAeonAgents::Agents::DocumenterAgent
          File.write('README.md', <<~README)
            # Test Project

            This is a test project.
          README
          {}
        else
          {}
        end
      }
    )
    stub_review_content
  end

  it_behaves_like 'an agent with common behavior', described_class


  it 'implements the requirements successfully' do
    with_git_workspace(files: { 'test.txt' => "original\n" }) do
      described_class.new(session_id: nil, commit: false, pull_request: false).run(requirements: 'Add a new feature')

      plan_generator_run_call = find_run_calls_for(XAeonAgents::Agents::PlanGeneratorAgent)
      expect(plan_generator_run_call).not_to be_nil
      expect(plan_generator_run_call[:kwargs]).to eq(
        requirements: 'Add a new feature',
        user_instructions: {
          ordered_list: [
            "Read the initial requirements from the artifact named `#{plan_generator_run_call[:agent].artifact_ref(:requirements)}`",
            'Analyze the project files',
            "Create an artifact named `#{plan_generator_run_call[:agent].artifact_ref(:plan)}` with a complete and detailed " \
              'step-by-step implementation plan in Markdown format'
          ]
        }
      )

      coder_run_call = find_run_calls_for(XAeonAgents::Agents::CoderAgent)
      expect(coder_run_call).not_to be_nil
      expect(coder_run_call[:kwargs]).to eq(
        plan: 'Detailed step-by-step plan for requirements "Add a new feature"',
        user_instructions: "Follow all the steps of the implementation plan described in the artifact named `#{coder_run_call[:agent].artifact_ref(:plan)}`."
      )

      documenter_run_call = find_run_calls_for(XAeonAgents::Agents::DocumenterAgent)
      expect(documenter_run_call).not_to be_nil
      expect(documenter_run_call[:kwargs]).to eq(
        requirements: 'Add a new feature',
        plan: 'Detailed step-by-step plan for requirements "Add a new feature"',
        files_diffs: <<~EO_ARTIFACT,
          ### New untracked files

          #### new_feature.rb
          ```
          puts 'New feature added'

          ```


          ### git diff

          ```

          ```
        EO_ARTIFACT
        user_instructions: {
          ordered_list: [
            <<~EO_STEP,
              Analyze the initial requirements from the artifact named `#{documenter_run_call[:agent].artifact_ref(:requirements)}`

              - Those give you information about the requirements you should be documenting.
            EO_STEP
            <<~EO_STEP,
              Analyze all the steps of the implementation plan from the artifact named `#{documenter_run_call[:agent].artifact_ref(:plan)}`

              - Those give you every step that should have been followed for this new development.
            EO_STEP
            <<~EO_STEP,
              Analyze the concrete changes from the artifact named `#{documenter_run_call[:agent].artifact_ref(:files_diffs)}`

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

      tester_run_call = find_run_calls_for(XAeonAgents::Agents::TesterAgent)
      expect(tester_run_call).to be_nil

      expect(File.exist?('README.md')).to be true
      expect(File.read('README.md')).to eq(<<~README)
        # Test Project

        This is a test project.
      README
    end
  end
end
