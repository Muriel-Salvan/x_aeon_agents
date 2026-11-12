module XAeonAgentsTest
  module Agents
    # Cline-based test agent used to validate how output artifacts are persisted as files.
    # It emulates the Cline behavior of writing output artifacts to files, without invoking the Cline CLI.
    class TestClineArtifactsAgent < ComposableAgents::Cline::Agent
      prepend XAeonAgents::AgentDefaults

      # @return [Array<String>] The rendered user prompts received by this agent
      attr_reader :received_prompts

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          markdown_input: {
            description: 'A Markdown input artifact',
            type: :markdown
          },
          text_input: {
            description: 'A text input artifact',
            type: :text
          },
          json_input: {
            description: 'A JSON input artifact',
            type: :json
          }
        }
      end

      # Define output artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        {
          markdown_artifact: {
            description: 'A Markdown output artifact',
            type: :markdown
          },
          text_artifact: {
            description: 'A text output artifact',
            type: :text
          },
          json_artifact: {
            description: 'A JSON output artifact',
            type: :json
          }
        }
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Constructor kwargs as computed by the AgentDefaults mixin
      def initialize(**agent_params)
        super
        @received_prompts = []
      end

      private

      # Write the output artifact files like a Cline agent would do, remembering the prompt, then read them back
      # so that they are saved as output artifacts.
      #
      # @param user_prompt [String] The rendered user prompt
      # @return [String] The output of the prompt
      def prompt(user_prompt)
        @received_prompts << user_prompt
        File.write(artifact_ref(:markdown_artifact), "# Written Markdown artifact\n")
        File.write(artifact_ref(:text_artifact), "Written text artifact\n")
        File.write(artifact_ref(:json_artifact), JSON.pretty_generate({ 'written' => true }))
        parse_output_artifacts('')
        'Artifacts written'
      end
    end
  end
end
