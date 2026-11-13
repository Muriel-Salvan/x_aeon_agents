# Shared examples validating that an agent's prompts constrain the usage of the tools available to Cline agents.
# The constraint is factorized in XAeonAgents::Helpers, but its expected content is asserted
# literally here so that a change of wording in the helpers is caught by the agent specs.
#
# @param agent_class [Class] The agent class to be tested. It should be one of the Cline agents.
shared_examples 'an agent constrained to use the Cline tools', :cline_tools do |agent_class|
  describe "testing agent class #{agent_class}" do
    it 'tells how to use the Cline tools' do
      expect(agent_class.new.constraints).to include(
        <<~EO_CONSTRAINT.rstrip
          - The `run_commands` tool takes ONE shell script as a plain string.
            - NEVER wrap it in `[ ]` or JSON.
            - One command per call; chain commands with `&&` only on one line.
            - Never use multi-line heredocs.
          - Always use the `editor` tool to write files.
          - You are a single agent: there is no team. NEVER call `team_*` tools: they will fail and count as mistakes.
        EO_CONSTRAINT
      )
    end
  end
end
