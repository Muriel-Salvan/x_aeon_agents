# Shared examples validating that agents are configurable through the config DSL
# (using the configure_agent method of the .x_aeon_agents.rb config files).
#
# The test scenarios are executed with the real CLI command instantiating the agents: the arguments
# of the run_cli call are given as parameters of the shared examples. The calling spec file is
# responsible for setting up the environment needed by its CLI scenario (git workspace, Github mocks,
# stubs of interactive prompts...) so that all the agents of the scenario get instantiated.

# Default stub handler for AI agents: returns a mocked value for each expected output artifact, so
# that orchestrator agents executing the scenario get meaningful artifacts from their sub-agents.
DEFAULT_AI_STUB_HANDLER = lambda do |agent, **_kwargs|
  agent.track_message(message: 'Mocked AI response', author: 'assistant')
  agent.send(:output_artifacts_contracts).keys.to_h { |artifact| [artifact, "Mocked #{artifact}"] }
end

shared_examples 'an agent configurable through the config DSL' do |agent_class, *run_cli_args, configurable_kwarg: :name, stub_handler: DEFAULT_AI_STUB_HANDLER|
  let(:agent_class_name) { agent_class.name.split('::').last }

  # Run the CLI scenario with a project .x_aeon_agents.rb config file written with the given content,
  # and return the instantiation of the tested agent class recorded during the run.
  #
  # @param config_content [String] Content of the project config file to load
  # @param tested_agent_class [Class] The agent class to be tested
  # @param scenario_cli_args [Array<String>] Arguments given to run_cli to execute the scenario
  # @param ai_stub_handler [#call] Stub handler for AI agents' run method (see #stub_agent_run)
  # @return [Hash{Symbol => Object}] The recorded instantiation of tested_agent_class
  def run_agent_config_scenario(config_content, tested_agent_class, scenario_cli_args, ai_stub_handler)
    stub_agent_instantiations
    stub_agent_run(stub_handler: ai_stub_handler)
    File.write('.x_aeon_agents.rb', config_content)
    begin
      run_cli(*scenario_cli_args)
    rescue RSpec::Expectations::ExpectationNotMetError => e
      raise <<~EO_FAILURE
        #{e.message}
        STDERR:
        #{stderr}
        STDOUT:
        #{stdout}
      EO_FAILURE
    end
    instantiation = find_instantiation_for(tested_agent_class)
    expect(instantiation).not_to be_nil, "Agent #{tested_agent_class} was not instantiated by the CLI scenario"
    instantiation
  end

  it "applies the #{configurable_kwarg} configured with configure_agent when initializing #{agent_class}" do
    configured_value = "Configured #{agent_class_name}"
    instantiation = run_agent_config_scenario(
      <<~CONFIG, agent_class, run_cli_args, stub_handler
        configure_agent(:#{agent_class_name}) do
          { #{configurable_kwarg}: '#{configured_value}' }
        end
      CONFIG
    )
    expect(instantiation[:kwargs][configurable_kwarg]).to eq configured_value
  end

  it "lets several configure_agent calls read and modify the configuration of #{agent_class}" do
    instantiation = run_agent_config_scenario(
      <<~CONFIG, agent_class, run_cli_args, stub_handler
        configure_agent(:#{agent_class_name}) do
          { #{configurable_kwarg}: 'initial' }
        end
        configure_agent(:#{agent_class_name}) do |agent_config|
          agent_config[:#{configurable_kwarg}] = "\#{agent_config[:#{configurable_kwarg}]} modified"
          agent_config
        end
      CONFIG
    )
    expect(instantiation[:kwargs][configurable_kwarg]).to eq 'initial modified'
  end

  it "lets explicitly given kwargs take precedence over the configured ones for #{agent_class}" do
    run_agent_config_scenario(
      <<~CONFIG, agent_class, run_cli_args, stub_handler
        configure_agent(:#{agent_class_name}) do
          { #{configurable_kwarg}: 'from-config' }
        end
      CONFIG
    )
    explicit_value = 'explicit'
    agent = agent_class.new(configurable_kwarg => explicit_value)
    expect(agent.public_send(configurable_kwarg)).to eq explicit_value
  end

  it "ignores configure_agent calls for other agent classes when initializing #{agent_class}" do
    instantiation = run_agent_config_scenario(
      <<~CONFIG, agent_class, run_cli_args, stub_handler
        configure_agent(:SomeOtherAgent) do
          { #{configurable_kwarg}: 'should-not-apply' }
        end
      CONFIG
    )
    expect(instantiation[:kwargs][configurable_kwarg]).not_to eq 'should-not-apply'
  end
end
