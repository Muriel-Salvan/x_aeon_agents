describe XAeonAgents::Cli, '#implement' do
  before do
    stub_agent_run(agent_classes: [XAeonAgents::Agents::DeveloperAgent])
  end

  it 'implements the given requirements with default arguments when no option is given' do
    run_cli 'implement', 'Add authentication middleware'
    expect(find_new_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      commit: false,
      pull_request: false,
      session_id: nil
    )
    expect(find_run_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      requirements: 'Add authentication middleware'
    )
  end

  it 'commits at every step when the --commit option is given' do
    run_cli 'implement', 'Add authentication middleware', '--commit'
    expect(find_new_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      commit: true,
      pull_request: false,
      session_id: nil
    )
  end

  it 'creates a Pull Request when the --pr option is given' do
    run_cli 'implement', 'Add authentication middleware', '--pr'
    expect(find_new_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      commit: false,
      pull_request: true,
      session_id: nil
    )
  end

  it 'commits and creates a Pull Request when the --commit and --pr options are given' do
    run_cli 'implement', 'Add authentication middleware', '--commit', '--pr'
    expect(find_new_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      commit: true,
      pull_request: true,
      session_id: nil
    )
  end

  it 'transfers the session id given from the command line' do
    run_cli 'implement', 'Add authentication middleware', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      commit: false,
      pull_request: false,
      session_id: 'my-session'
    )
  end
end
