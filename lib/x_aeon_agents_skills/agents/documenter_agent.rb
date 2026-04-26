module XAeonAgentsSkills
  module Agents
    # Agent responsible for updating documentation after a new development
    class DocumenterAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          requirements: 'Initial requirements',
          plan: 'Implementation plan that introduced features and fixes to be documented',
          files_diffs: 'Full list of files changes and differences that have been done to implement the initial requirements following the implementation plan'
        }
      end

      # Constructor
      #
      # @param agent_params [Hash<Symbol, Object>] Parameters driving the agent model selection
      def initialize(**agent_params)
        super(
          name: 'Documenter',
          objective: 'Ensure documentation reflects the current product behavior and usage after a new development.',
          instructions: {
            ordered_list: [
              <<~EO_STEP,
                Analyze the initial requirements from the artifact named `requirements`

                - Those give you information about the requirements you should be documenting.
              EO_STEP
              <<~EO_STEP,
                Analyze all the steps of the implementation plan from the artifact named `plan`

                - Those give you every step that should have been followed for this new development.
              EO_STEP
              <<~EO_STEP,
                Analyze the concrete changes from the artifact named `files_diffs`

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
          },
          constraints: <<~EO_CONSTRAINTS,
            - Only update documentation files.
            - Do NOT change any code or test.
            - NEVER document the fact that a change happened.
            - NEVER explain that something was removed, renamed, or fixed.
            - Documentation describes the CURRENT STATE only.
            - Documentation is NOT a changelog.
          EO_CONSTRAINTS
          **agent_params
        )
      end
    end
  end
end
