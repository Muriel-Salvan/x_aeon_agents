# Shared examples validating that an agent's prompts allow it to write its output artifacts.
# The artifact sentences are factorized in XAeonAgents::Helpers, but their expected content is asserted
# literally here so that a change of wording in the helpers is caught by the agent specs.
#
# @param agent_class [Class] The agent class to be tested. It should be one of the agents from
#   XAeonAgents::Agents (or sub-namespaces) that have to write output artifacts.
# @param output_artifact_names [Array<Symbol>] Names of the output artifacts the agent has to write.
shared_examples 'an agent allowed to write its output artifacts' do |agent_class, output_artifact_names|
  describe "testing agent class #{agent_class}" do
    it 'allows writing only its output artifact files' do
      agent = agent_class.new
      artifact_paths = output_artifact_names.map { |artifact_name| "`#{agent.artifact_ref(artifact_name)}`" }.join(', ')
      expect(agent.constraints).to include(
        "You are allowed to read and write the artifact files at #{artifact_paths}, " \
          'even if they are not part of the current repository'
      )
    end
  end
end
