describe XAeonAgents::Cli, '#interpret_diffs' do
  before do
    stub_agent_run(
      agent_classes: [XAeonAgents::Agents::GitDiffInterpreterAgent],
      stub_handler: lambda { |_agent, **_kwargs|
        {
          one_line_summary: '  Mocked 1-line summary  ',
          change_intent: "\n  Mocked change intent\n\n"
        }
      }
    )
  end

  it 'interprets the diffs with the default base ref and prints the result' do
    run_cli 'interpret-diffs'
    expect(find_run_calls_for(XAeonAgents::Agents::GitDiffInterpreterAgent)[:kwargs]).to eq(git_ref_base: 'HEAD')
    expect(stdout).to eq <<~EO_STDOUT
      ===== Code diffs interpretation:

      Mocked 1-line summary

      Mocked change intent
    EO_STDOUT
  end

  it 'uses the base ref given from the command line' do
    run_cli 'interpret-diffs', 'main'
    expect(find_run_calls_for(XAeonAgents::Agents::GitDiffInterpreterAgent)[:kwargs]).to eq(git_ref_base: 'main')
  end

  it 'transfers the session id given from the command line' do
    run_cli 'interpret-diffs', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::GitDiffInterpreterAgent)[:kwargs]).to eq(session_id: 'my-session')
  end
end
