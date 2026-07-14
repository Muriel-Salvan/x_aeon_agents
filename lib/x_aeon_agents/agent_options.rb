module XAeonAgents
  # Provide agent options for different agent categories
  class AgentOptions
    # @!group Public API

    # Get an agent's option for a given agent category.
    # Those options can be given directly to the agent's constructor to tune it for the desired category.
    #
    # @param agent_category [String] The agent category for which we want the agent's options
    # @return [Hash{Symbol => Object}, nil] The corresponding agent's options, or nil if none
    def [](agent_category)
      # Lazy-evaluate it if needed
      options[agent_category] = options[agent_category].call if options[agent_category].is_a?(Proc)
      options[agent_category]
    end

    # Set an agent's option for a given agent category.
    #
    # @param agent_category [String] The agent category for which we want the agent's options
    # @param agent_options [Hash{Symbol => Object}, #call -> Hash] The corresponding agent's options (can be lazily evaluated)
    def []=(agent_category, agent_options)
      options[agent_category] = agent_options
    end

    private

    # @return [Hash{String => Hash{Symbol => Object}, #call -> Hash}] The memoized options (can be lazily evaluated), per agent category.
    def options
      @options ||= {
        'free_simple' => {
          model: 'openrouter/free',
          strategy: ComposableAgents::PromptRenderingStrategy::Markdown
        },
        'free_complex' => proc do
          {
            # model: 'deepseek/deepseek-v4-flash',
            model: 'stepfun/step-3.7-flash',
            api_key: Config.cline_api_key,
            cli_options: Config.default_cline_cli_args
          }
        end,
        'free_complex_planning' => proc do
          {
            # model: 'deepseek/deepseek-v4-flash',
            model: 'stepfun/step-3.7-flash',
            api_key: Config.cline_api_key,
            cli_options: Config.default_cline_cli_args.merge(
              {
                plan: true
              }
            ),
            configure_global: proc do |global_settings|
              global_settings.disabled_tools = %w[editor run_commands]
            end
          }
        end
      }
    end
  end
end
