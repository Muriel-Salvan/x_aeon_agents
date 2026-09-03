describe XAeonAgents::Cli, '#implement_issue' do
  before do
    stub_agent_run(agent_classes: [XAeonAgents::Agents::IssueImplementerAgent])
  end

  it 'implements the given issue with commits and Pull Request enabled by default' do
    run_cli 'implement-issue', '15'
    expect(find_new_calls_for(XAeonAgents::Agents::IssueImplementerAgent)[:kwargs]).to eq(
      commit: true,
      pull_request: true,
      session_id: nil
    )
    expect(find_run_calls_for(XAeonAgents::Agents::IssueImplementerAgent)[:kwargs]).to eq(github_issue_number: 15)
  end

  it 'transfers the session id given from the command line' do
    run_cli 'implement-issue', '15', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::IssueImplementerAgent)[:kwargs]).to eq(
      commit: true,
      pull_request: true,
      session_id: 'my-session'
    )
  end

  it 'fails when the given issue number is not an integer' do
    run_cli 'implement-issue', 'abc', expect_failure: true
    expect(exit_status).to eq 1
    expect(stderr).to include 'invalid value for Integer'
    expect(find_run_calls_for(XAeonAgents::Agents::IssueImplementerAgent)).to be_nil
  end
end
