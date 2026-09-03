describe XAeonAgents::Cli, '#start_task' do
  before do
    stub_agent_run(agent_classes: [XAeonAgents::Agents::TaskStarterAgent])
  end

  it 'opens a worktree for the branch given with the --branch option' do
    run_cli 'start-task', '--branch', 'feature/my-task'
    expect(find_run_calls_for(XAeonAgents::Agents::TaskStarterAgent)[:kwargs]).to eq(branch_name: 'feature/my-task')
  end

  it 'prompts for a branch name when the --branch option is not given' do
    allow($stdin).to receive(:gets).and_return("feature/typed-branch\n")
    run_cli 'start-task'
    expect(stdout).to eq "Branch name:\n"
    expect(find_run_calls_for(XAeonAgents::Agents::TaskStarterAgent)[:kwargs]).to eq(branch_name: 'feature/typed-branch')
  end

  it 'transfers the session id given from the command line' do
    run_cli 'start-task', '--branch', 'feature/my-task', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::TaskStarterAgent)[:kwargs]).to eq(session_id: 'my-session')
  end
end
