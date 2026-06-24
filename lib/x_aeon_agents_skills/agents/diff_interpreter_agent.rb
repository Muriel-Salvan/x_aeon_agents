module XAeonAgentsSkills
  module Agents
    # Agent responsible for analyzing files differences in a repository
    class DiffInterpreterAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract
      prepend XAeonAgentsSkills::AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        { files_diff: 'The full list of files changes and differences that have been done' }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {
          change_intent: {
            description: 'The full explanation of the changes, as in a git commit description',
            type: :text
          }
        }
      end

      # Constructor
      #
      # @param agent_params [Hash<Symbol, Object>] Parameters driving the agent model selection
      def initialize(**agent_params)
        super(
          name: 'Diff interpreter',
          role: 'You are a files diff interpreter agent',
          objective: <<~EO_OBJECTIVE,
            Interpret files modifications and explain the changes properly with its meaning and intent.

            The goals are:
            - Get a general explanation of those changes.
            - Identify the kind of changes involved (new features, feature change, bug fix, documentation...).
            - Identify the components that are impacted by those changes (a specific plugin, CLI, UI...).
          EO_OBJECTIVE
          instructions: {
            ordered_list: [
              <<~EO_INSTRUCTIONS,
                Read and analyze ALL file changes from the artifact named `files_diff`

                - Those changes are the ones you must explain.
              EO_INSTRUCTIONS
              <<~EO_INSTRUCTIONS,
                Analyze the project files

                - Those files give you context to understand the changes.
                - Changes made on those files should NOT be explained unless they are part of the artifact named `files_diff`.
              EO_INSTRUCTIONS
              <<~EO_INSTRUCTIONS,
                Create an artifact named `change_intent` to explain properly the changes reported by the artifact named `files_diff`

                - You MUST create an artifact named `change_intent` that contains:
                1. A general explanation of the changes, their meaning and intent in the context of this project.
                2. The types of changes (feature, bug fix, documentation, etc.).
                3. The impacted architectural components (backend, login screen, CLI, etc.).
                - Describe those changes in a way similar to a git commit comment or a pull request description.
                - ONLY cover changes from the artifact named `files_diff`.
                - Do NOT explain changes for other files.
              EO_INSTRUCTIONS
            ]
          },
          constraints: <<~EO_CONSTRAINTS,
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - You must ONLY explain the changes of the artifact named `files_diff`, NOT other changes.
            - You already have ALL the information required.
            - The user's intent is fully specified.
            - The conversation log is provided for context only. You MUST NOT ask follow-up questions.
          EO_CONSTRAINTS
          **agent_params
        )
      end
    end
  end
end
