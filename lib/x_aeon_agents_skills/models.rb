module XAeonAgentsSkills
  # Give plenty of possible model parameters configurations based on different use cases
  module Models
    class << self
      # Simple task, using a free model
      #
      # @return [Hash<Symbol, Object>] Corresponding model parameters
      def free_simple
        {
          model: 'inclusionai/ling-2.6-flash:free',
          strategy: ComposableAgents::PromptRenderingStrategy::Markdown
        }
      end

      # Complex task, using a free model
      #
      # @return [Hash<Symbol, Object>] Corresponding model parameters
      def free_complex
        {
          model: 'clinecli/arcee-ai/trinity-large-preview:free',
          strategy: ComposableAgents::PromptRenderingStrategy::Markdown,
          params: {
            # cline: {
            #   plan_mode: false,
            #   config: XAeonAgentsSkills::Agents.read_only_config.merge(
            #     doubleCheckCompletionEnabled: false
            #   ),
            #   cli_args: XAeonAgentsSkills::Agents.config[:default_cline_cli_args],
            #   skills: %w[
            #     applying-ruby-conventions
            #     applying-test-conventions
            #     enforcing-project-rules
            #   ]
            # }
          }
        }
      end
    end
  end
end
