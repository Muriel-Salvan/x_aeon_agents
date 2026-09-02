describe XAeonAgents::AgentDefaults do
  # Stub the AI agents' run method: agents are only instantiated here, never run,
  # but the frameworks they rely on still need to be initialized in their constructors.
  before do
    stub_agent_run
  end

  # Instantiate an agent class and return the recorded instantiation, ie. the agent instance
  # with the constructor kwargs as recorded by the instantiation spy at the ComposableAgents::Agent
  # level (ie. after the AgentDefaults mixin applied framework defaults, config DSL procs and
  # explicitly given kwargs, but after the framework classes consumed their own kwargs).
  #
  # @param agent_class [Class] The agent class to instantiate
  # @param kwargs [Hash] Explicit kwargs to give to the constructor
  # @return [Hash{Symbol => Object}] The recorded instantiation, with :agent and :kwargs keys
  def instantiate_agent_with_defaults(agent_class, **kwargs)
    stub_agent_instantiations
    agent_class.new(**kwargs)
    find_instantiation_for(agent_class)
  end

  it 'gives the Cline framework defaults to Cline agents' do
    # TODO: Don't use real agents from XAeonAgents::Agents in this file. Create 3 different agents (1 of type Cline, 1 of type AiAgent, 1 of type normal Agent) in the tests framework (XAeonAgentsTest::Agents:: module to be created), all prepending AgentDefaults and test on those agents instead. That should simplify mocking or spying: those agents can define whatever getters they need to spy on how they were called.
    agent = instantiate_agent_with_defaults(XAeonAgents::Agents::CoderAgent)[:agent]

    expect(agent.instance_variable_get(:@api_key).to_unprotected).to eq 'test-cline-api-key'
    expect(agent.instance_variable_get(:@cli_options)).to eq(XAeonAgents::Config.default_cline_cli_args)
  end

  it 'gives the AiAgents framework defaults to AI agents' do
    agent = instantiate_agent_with_defaults(XAeonAgents::Agents::DiffInterpreterAgent)[:agent]

    expect(agent.singleton_class.include?(ComposableAgents::PromptRenderingStrategy::Markdown)).to be true
  end

  it 'gives default session properties to all agents' do
    instantiation = instantiate_agent_with_defaults(XAeonAgents::Agents::CoderAgent)
    session_id = described_class.singleton_session_id

    expect(instantiation[:kwargs][:composable_agents_dir]).to eq "#{XAeonAgents::Config.data_dir}/sessions/#{session_id}/composable_agents"
    expect(instantiation[:agent].instance_variable_get(:@run_id)).to eq "#{session_id}-CoderAgent"
  end

  # TODO: Make this test for the 3 kinds of agent: Cline, AiAgents and normal Agent.
  it 'lets the config DSL overwrite the framework defaults' do
    XAeonAgents::ConfigDsl.new.evaluate(<<~CONFIG)
      configure_agent(:CoderAgent) do
        {
          model: 'config-model',
          cli_options: { thinking: 'low' }
        }
      end
    CONFIG

    agent = instantiate_agent_with_defaults(XAeonAgents::Agents::CoderAgent)[:agent]

    expect(agent.instance_variable_get(:@model)).to eq 'config-model'
    expect(agent.instance_variable_get(:@cli_options)).to eq(thinking: 'low')
    # Defaults not overwritten by the config DSL are still applied
    expect(agent.instance_variable_get(:@api_key).to_unprotected).to eq 'test-cline-api-key'
  end
end
