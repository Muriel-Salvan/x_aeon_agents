module XAeonAgentsSkills
  module Agents
    # Agent responsible for summarizing code change intent into a single line
    class OneLineCodeDiffSummarizerAgent < ComposableAgents::AiAgents::Agent
      prepend ComposableAgents::Mixins::ArtifactContract

      # Constructor
      def initialize
        super(
          name: '1-line code diff summarizer',
          role: 'You are a 1-line code diff summarizer agent',
          objective: 'Produce a 1-line summary of a code change intent report.',
          instructions: {
            ordered_list: [
              <<~EO_INSTRUCTIONS,
                Read the artifact named `change_intent` to understand what you need to summarize

                - This artifact contains already all the information you need to summarize.
                - You don't need to gather more information thatn this.
              EO_INSTRUCTIONS
              <<~EO_INSTRUCTIONS
                Create an artifact named `one_line_summary` to provide a 1-line summary of the code change intent described in the artifact named `change_intent`

                - Summarize the change intent the same way you would write a git commit comment title.
                - Follow standard git commit title conventions using `feat`, `fix`, etc... with impacted component names.
              EO_INSTRUCTIONS
            ]
          },
          constraints: <<~EO_CONSTRAINTS,
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - You already have ALL the information required.
            - The user's intent is fully specified.
            - You MUST NOT ask follow-up questions.
          EO_CONSTRAINTS
          model: 'inclusionai/ling-2.6-flash:free',
          strategy: ComposableAgents::PromptRenderingStrategy::Markdown,
          params: {
            # cline: {
            #   plan_mode: false,
            #   config: XAeonAgentsSkills::Agents.read_only_config.merge(
            #     doubleCheckCompletionEnabled: false
            #   ),
            #   cli_args: XAeonAgentsSkills::Agents.config[:default_cline_cli_args],
            #   skills: XAeonAgentsSkills::Agents.config[:default_cline_skills]
            # }
          }
        )
      end

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        { change_intent: 'Full description of the code changes, their meaning and intent' }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        { one_line_summary: '1-line summary of the code change intent' }
      end
    end
  end
end
