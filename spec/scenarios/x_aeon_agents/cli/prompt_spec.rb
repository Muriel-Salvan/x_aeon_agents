describe XAeonAgents::Cli, '#prompt' do
  # Mocked conversation of the Executor agent, overridable in contexts
  let(:mocked_conversation) do
    lambda { |agent, **_kwargs|
      agent.track_message(message: 'Mocked AI response', author: 'assistant')
      {}
    }
  end

  before do
    stub_agent_run(stub_handler: mocked_conversation)
  end

  it 'sends the user prompt to the Executor agent and prints its response' do
    run_cli 'prompt', 'What is the capital of France?'
    expect(find_run_calls_for(XAeonAgents::Agents::ExecutorAgent)[:kwargs]).to eq(
      user_instructions: 'What is the capital of France?'
    )
    expect(stdout).to include "Mocked AI response\n"
  end

  it 'transfers the session id given from the command line' do
    run_cli 'prompt', 'What is the capital of France?', '--session-id', 'my-session'
    expect(find_new_calls_for(XAeonAgents::Agents::ExecutorAgent)[:kwargs][:composable_agents_dir]).to include 'my-session'
  end

  context 'with a multi-message conversation' do
    let(:mocked_conversation) do
      lambda { |agent, **_kwargs|
        agent.track_message(message: 'First response', author: 'assistant')
        agent.track_message(message: 'Final answer', author: 'assistant')
        {}
      }
    end

    it 'prints only the last message of the conversation' do
      run_cli 'prompt', 'What is the capital of France?'
      expect(stdout).to include "Final answer\n"
      expect(stdout).not_to include 'First response'
    end
  end
end
