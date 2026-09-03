require_relative 'shared_examples/common_behavior'

describe XAeonAgents::Agents::ExecutorAgent do
  it_behaves_like 'an agent with common behavior', described_class

  context 'with a simple prompt' do
    it 'prints the last message of the AI response' do
      stub_agent_run(
        stub_handler: lambda { |agent, **_kwargs|
          agent.track_message(message: 'Hello from AI', author: 'assistant')
          {}
        }
      )
      agent = described_class.new(session_id: nil)
      agent.run(user_instructions: 'What is the capital of France?')
      expect(agent.conversation.last[:message]).to include('Hello from AI')
    end

    it 'sends user_instructions to the agent' do
      stub_agent_run
      agent = described_class.new(session_id: nil)
      agent.run(user_instructions: 'Explain this code')
      expect(agent_run_calls.last[:kwargs]).to eq(user_instructions: 'Explain this code')
    end

    it 'captures exactly one agent run call' do
      stub_agent_run
      agent = described_class.new(session_id: nil)
      agent.run(user_instructions: 'test')
      expect(agent_run_calls.size).to eq(1)
    end
  end

  context 'with a custom session ID' do
    it 'passes session_id to ExecutorAgent' do
      stub_agent_run
      agent = described_class.new(session_id: 'my-custom-session')
      agent.run(user_instructions: 'test')
      expect(agent_new_calls.last[:kwargs][:composable_agents_dir]).to include('my-custom-session')
    end
  end

  context 'with a multi-message conversation' do
    it 'prints only the last message' do
      stub_agent_run(
        stub_handler: lambda { |agent, **_kwargs|
          agent.track_message(message: 'First response', author: 'assistant')
          agent.track_message(message: 'Second response', author: 'assistant')
          agent.track_message(message: 'Final answer', author: 'assistant')
          {}
        }
      )
      agent = described_class.new(session_id: nil)
      agent.run(user_instructions: 'test')
      last_message = agent.conversation.last[:message]
      expect(last_message).to include('Final answer')
      expect(last_message).not_to include('First response')
      expect(last_message).not_to include('Second response')
    end
  end
end
