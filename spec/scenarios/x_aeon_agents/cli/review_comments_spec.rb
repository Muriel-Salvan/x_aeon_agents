describe XAeonAgents::Cli, '#review_comments' do
  before do
    stub_agent_run(agent_classes: [XAeonAgents::Agents::ReviewResolverAgent])
  end

  it 'addresses comments of the given Pull Request number' do
    run_cli 'review-comments', '42'
    expect(find_new_calls_for(XAeonAgents::Agents::ReviewResolverAgent)[:kwargs]).to eq(session_id: nil)
    expect(find_run_calls_for(XAeonAgents::Agents::ReviewResolverAgent)[:kwargs]).to eq(pull_request_number: 42)
  end

  it 'auto-detects the Pull Request number when it is not given' do
    run_cli 'review-comments'
    expect(find_run_calls_for(XAeonAgents::Agents::ReviewResolverAgent)[:kwargs]).to eq(pull_request_number: nil)
  end

  it 'transfers the session id given from the command line' do
    run_cli 'review-comments', '42', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::ReviewResolverAgent)[:kwargs]).to eq(session_id: 'my-session')
  end

  it 'fails when the given Pull Request number is not an integer' do
    run_cli 'review-comments', 'abc', expect_failure: true
    expect(exit_status).to eq 1
    expect(stderr).to include 'invalid value for Integer'
    expect(find_run_calls_for(XAeonAgents::Agents::ReviewResolverAgent)).to be_nil
  end
end
