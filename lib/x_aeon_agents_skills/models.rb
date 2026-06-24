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
          model: 'deepseek/deepseek-v4-flash',
          api_key: Configuration.config[:cline_api_key],
          cli_options: Configuration.config[:default_cline_cli_args]
        }
      end

      # Complex task, using a free model for planning (Read-Only)
      #
      # @return [Hash<Symbol, Object>] Corresponding model parameters
      def free_complex_planning
        {
          # model: 'deepseek/deepseek-v4-flash',
          model: 'stepfun/step-3.7-flash',
          api_key: Configuration.config[:cline_api_key],
          cli_options: Configuration.config[:default_cline_cli_args].merge(
            {
              plan: true
            }
          ),
          configure_global: proc do |global_settings|
            global_settings.disabled_tools = %w[editor run_commands]
          end
        }
      end
    end
  end
end
