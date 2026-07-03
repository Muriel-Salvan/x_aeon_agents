describe XAeonAgents::Cli, '#prompt' do
  context 'with a simple prompt' do
    it 'prints the last message of the AI response' do
      stub_agent_run(conversation: [{ message: 'Hello from AI' }])
      run_cli 'prompt', 'What is the capital of France?'
      expect(stdout).to include('Hello from AI')
    end

    it 'sends user_instructions to the agent' do
      stub_agent_run
      run_cli 'prompt', 'Explain this code'
      expect(last_agent_run_call[:kwargs]).to eq(user_instructions: 'Explain this code')
    end

    it 'captures exactly one agent run call' do
      stub_agent_run
      run_cli 'prompt', 'test'
      expect(agent_run_calls.size).to eq(1)
    end
  end

  context 'with a custom session ID' do
    it 'passes session_id to ExecutorAgent' do
      stub_agent_run
      run_cli 'prompt', 'test', '--session-id', 'my-custom-session'
      expect(last_agent_new_call[:kwargs][:composable_agents_dir]).to include('my-custom-session')
    end
  end

  context 'with a multi-message conversation' do
    it 'prints only the last message' do
      stub_agent_run(
        conversation: [
          { message: 'First response' },
          { message: 'Second response' },
          { message: 'Final answer' }
        ]
      )
      run_cli 'prompt', 'test'
      expect(stdout).to include('Final answer')
      expect(stdout).not_to include('First response')
      expect(stdout).not_to include('Second response')
    end
  end
end
