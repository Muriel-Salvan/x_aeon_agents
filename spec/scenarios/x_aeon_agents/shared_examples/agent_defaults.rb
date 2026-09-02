# Shared examples validating the common behavior of all agents using the AgentDefaults mixin:
# framework defaults application, default session properties, and config DSL overwriting of defaults.
#
# @param agent_class [Class] The agent class to be tested. It should be one of the test agents from
#   XAeonAgentsTest::Agents (ie. an agent prepending AgentDefaults and including
#   XAeonAgentsTest::Agents::Spy), so that its constructor kwargs can be spied upon.
# @param configured_kwargs [Hash{Symbol => Object}] The kwargs to be configured through the config
#   DSL (using the configure_agent method of the .x_aeon_agents.rb config files), expected to
#   overwrite the framework defaults. Values must be literals that can be embedded in the
#   generated config file content.
# @param expected_default_options [Hash{Symbol => Object}] The framework defaults expected to be applied
#   by the AgentDefaults mixin, per constructor kwarg name. Empty if the agent kind gets no
#   framework default.
# @param expected_default_options_kept [Hash{Symbol => Object}] The framework defaults that are not overwritten by
#   the config DSL, expected to still be applied.
# @param expected_singleton_modules [Array<Module>] The modules expected to be included in the
#   agent's singleton class after instantiation (eg. the prompt rendering strategies applied by
#   the AgentDefaults mixin or by the agent's framework class).
shared_examples 'an agent using AgentDefaults' do |
  agent_class,
  configured_kwargs:,
  expected_default_options:,
  expected_default_options_kept:,
  expected_singleton_modules: []
|
  # Name of the tested agent class, as used by the config DSL
  let(:agent_class_name) { agent_class.name.split('::').last }

  describe "testing agent class #{agent_class}" do
    describe 'validating initialization' do
      it 'gives default options' do
        agent = agent_class.new
        expected_default_options.each do |kwargs_name, expected_value|
          expect(agent.received_kwargs[kwargs_name]).to eq expected_value
        end
        expected_singleton_modules.each do |expected_module|
          expect(agent.singleton_class.include?(expected_module)).to be true
        end
      end

      it 'sets dedicated session properties' do
        agent = agent_class.new
        session_dir_regexp = %r{^#{Regexp.escape(XAeonAgents::Config.data_dir)}/sessions/([^/]+)/composable_agents$}
        expect(agent.received_kwargs[:composable_agents_dir]).to match session_dir_regexp
        expect(agent.run_id).to eq "#{agent.received_kwargs[:composable_agents_dir].match(session_dir_regexp)[1]}-#{agent_class_name}"
      end

      it 'lets the config DSL overwrite the default options' do
        XAeonAgents::ConfigDsl.new.evaluate <<~CONFIG
          configure_agent(:#{agent_class_name}) do
            {
              #{configured_kwargs.map { |kwargs_name, value| "#{kwargs_name}: #{value.inspect}" }.join(",\n  ")}
            }
          end
        CONFIG
        agent = agent_class.new
        configured_kwargs.each do |kwargs_name, expected_value|
          expect(agent.received_kwargs[kwargs_name]).to eq expected_value
        end
        # Defaults not overwritten by the config DSL are still applied
        expected_default_options_kept.each do |kwargs_name, expected_value|
          expect(agent.received_kwargs[kwargs_name]).to eq expected_value
        end
      end
    end
  end
end
