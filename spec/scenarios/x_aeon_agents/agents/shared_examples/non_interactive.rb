# Shared examples validating that an agent's prompts forbid the ask_question tool when no human is available.
# The non-interactive sentence is factorized in XAeonAgents::Helpers, but its expected content is asserted
# literally here so that a change of wording in the helpers is caught by the agent specs.
#
# @param agent_class [Class] The agent class to be tested. It should be one of the prompt-driven agents
#   (Cline or AiAgents kinds).
shared_examples 'an agent respecting the non-interactive mode', :non_interactive do |agent_class|
  describe "testing agent class #{agent_class}" do
    it 'forbids the ask_question tool when the interactive mode is disabled' do
      XAeonAgents::Config.interactive = false
      expect(agent_class.new.constraints).to include(
        '- You MUST NOT use the ask_question tool under any circumstances: ' \
          'you are running in non-interactive mode with no human user available, ' \
          'so proceed using your best judgment without asking'
      )
    end

    it 'does not mention ask_question when the interactive mode is enabled' do
      XAeonAgents::Config.interactive = true
      expect(agent_class.new.constraints).not_to include('ask_question')
    end
  end
end
