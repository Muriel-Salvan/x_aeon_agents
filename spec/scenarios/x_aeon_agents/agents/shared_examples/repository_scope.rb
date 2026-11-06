# Shared examples validating that an agent scopes its file accesses to the current repository.
# The repository sentences are factorized in XAeonAgents::Helpers, but their expected content is asserted
# literally here so that a change of wording in the helpers is caught by the agent specs.
#
# @param agent_class [Class] The agent class to be tested. It should be one of the agents from
#   XAeonAgents::Agents (or sub-namespaces) that need to access the repository's files.
# @param writable [Boolean] True if the agent is allowed to write files in the repository,
#   false if it is read-only (default).
shared_examples 'an agent scoped to the current repository' do |agent_class, writable: false|
  describe "testing agent class #{agent_class}" do
    let(:repository_path) { Dir.pwd }
    let(:access) { writable ? 'read and write' : 'read' }

    it 'tells in its system instructions the repository it is working on' do
      expect(system_instructions_text(agent_class.new)).to include(
        "The current repository in which you are working is `#{repository_path}`."
      )
    end

    it 'restricts its file accesses to the repository' do
      expect(agent_class.new.constraints).to include(
        "- You should only #{access} files that are part of the current repository: `#{repository_path}`"
      )
    end
  end
end
