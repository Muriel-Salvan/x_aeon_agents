module XAeonAgentsTest
  module Helpers
    # Helpers validating that agents are configurable through the config DSL
    # (using the configure_agent method of the .x_aeon_agents.rb config files).
    # The shared examples using these helpers are declared in
    # spec/scenarios/x_aeon_agents/cli/shared_examples/agent_configurability.rb.
    module AgentConfigurability
      # Record every agent instantiation performed by the tested code, with the constructor kwargs
      # as computed by the AgentDefaults mixin (ie. after application of the config DSL kwargs).
      def stub_agent_instantiations
        @agent_instantiations = []
        # Wire the prepended mixin's shared state to our test instance variables
        Stubs::AgentInstantiationSpy.instantiations = @agent_instantiations
        # Stub all agent classes
        return if ComposableAgents::Agent.ancestors.include?(Stubs::AgentInstantiationSpy)

        ComposableAgents::Agent.prepend(Stubs::AgentInstantiationSpy)
      end

      # @return [Array<Hash{Symbol => Object}>] Collector for captured `new` calls. Each entry has the following properties:
      #   - agent [ComposableAgents::Agent] The agent that was instantiated.
      #   - args [Array] All args given to the `new` method call.
      #   - kwargs [Hash] All kwargs given to the `new` method call.
      def agent_instantiations
        @agent_instantiations || []
      end

      # Find the first recorded instantiation of a specific agent class
      #
      # @param agent_class [Class] The agent class we are looking for
      # @return [Hash{Symbol => Object}, nil] The first matching instantiation (see #agent_instantiations), or nil if none found
      def find_instantiation_for(agent_class)
        agent_instantiations.find { |instantiation| instantiation[:agent].is_a?(agent_class) }
      end
    end
  end
end
