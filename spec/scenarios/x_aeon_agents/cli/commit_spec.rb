describe XAeonAgents::Cli, '#commit' do
  before do
    stub_agent_run(agent_classes: [XAeonAgents::Agents::CommitterAgent])
  end

  it 'commits with default arguments when no option is given' do
    run_cli 'commit'
    expect(find_new_calls_for(XAeonAgents::Agents::CommitterAgent)[:kwargs]).to eq(session_id: nil, stage: :if_empty)
    expect(find_run_calls_for(XAeonAgents::Agents::CommitterAgent)[:kwargs]).to eq({})
  end

  it 'uses the stage all strategy when the --stage all option is given' do
    run_cli 'commit', '--stage', 'all'
    expect(find_new_calls_for(XAeonAgents::Agents::CommitterAgent)[:kwargs]).to eq(session_id: nil, stage: :all)
  end

  it 'uses the stage none strategy when the --stage none option is given' do
    run_cli 'commit', '--stage', 'none'
    expect(find_new_calls_for(XAeonAgents::Agents::CommitterAgent)[:kwargs]).to eq(session_id: nil, stage: :none)
  end

  it 'transfers the session id given from the command line' do
    run_cli 'commit', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::CommitterAgent)[:kwargs]).to eq(session_id: 'my-session', stage: :if_empty)
  end
end
