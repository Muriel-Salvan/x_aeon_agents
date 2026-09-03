describe XAeonAgents::Cli, '#create_pr' do
  before do
    stub_agent_run(agent_classes: [XAeonAgents::Agents::PullRequestCreatorAgent])
  end

  it 'creates the Pull Request against the default base when no option is given' do
    run_cli 'create-pr'
    expect(find_run_calls_for(XAeonAgents::Agents::PullRequestCreatorAgent)[:kwargs]).to eq(base_sha: 'main')
  end

  it 'creates the Pull Request against the base given with the --base option' do
    run_cli 'create-pr', '--base', 'master'
    expect(find_run_calls_for(XAeonAgents::Agents::PullRequestCreatorAgent)[:kwargs]).to eq(base_sha: 'master')
  end

  it 'passes the requirements given with the --requirements option' do
    run_cli 'create-pr', '--requirements', 'Add a new Home button'
    expect(find_run_calls_for(XAeonAgents::Agents::PullRequestCreatorAgent)[:kwargs]).to eq(
      base_sha: 'main',
      requirements: 'Add a new Home button'
    )
  end

  it 'passes both the custom base and requirements when both options are given' do
    run_cli 'create-pr', '--base', 'master', '--requirements', 'Add a new Home button'
    expect(find_run_calls_for(XAeonAgents::Agents::PullRequestCreatorAgent)[:kwargs]).to eq(
      base_sha: 'master',
      requirements: 'Add a new Home button'
    )
  end

  it 'transfers the session id given from the command line' do
    run_cli 'create-pr', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::PullRequestCreatorAgent)[:kwargs]).to eq(session_id: 'my-session')
  end
end
