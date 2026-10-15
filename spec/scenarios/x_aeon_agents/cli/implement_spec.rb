describe XAeonAgents::Cli, '#implement' do
  before do
    stub_agent_run(agent_classes: [XAeonAgents::Agents::DeveloperAgent])
  end

  it 'implements the given requirements with default arguments when no option is given' do
    run_cli 'implement', 'Add authentication middleware'
    expect(find_new_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      commit: false,
      pr_base_ref: nil,
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
      pr_base_ref: nil,
      session_id: nil
    )
  end

  it 'creates a Pull Request when the --pr-base option is given' do
    run_cli 'implement', 'Add authentication middleware', '--pr-base', 'main'
    expect(find_new_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      commit: false,
      pr_base_ref: 'main',
      session_id: nil
    )
  end

  it 'commits and creates a Pull Request when the --commit and --pr-base options are given' do
    run_cli 'implement', 'Add authentication middleware', '--commit', '--pr-base', 'main'
    expect(find_new_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      commit: true,
      pr_base_ref: 'main',
      session_id: nil
    )
  end

  it 'transfers the session id given from the command line' do
    run_cli 'implement', 'Add authentication middleware', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::DeveloperAgent)[:kwargs]).to eq(
      commit: false,
      pr_base_ref: nil,
      session_id: 'my-session'
    )
  end
end
