# Shared examples validating the file format agents use for their artifacts.
# With file-based artifact strategies, an artifact type is publicly visible as the file extension of the artifact
# path that is given to the agent in its prompts, and that output artifacts are written to.
#
# @param agent_class [Class] The agent class to be tested. It should be a Cline agent, using a file-based
#   artifact strategy.
# @param input_types [Hash{Symbol => Symbol}] Expected type, per input artifact name.
# @param output_types [Hash{Symbol => Symbol}] Expected type, per output artifact name.
shared_examples 'an agent declaring artifact types' do |agent_class, input_types: {}, output_types: {}|
  describe "testing agent class #{agent_class}" do
    let(:extension_by_type) { { text: '.txt', markdown: '.md', json: '.json' } }
    let(:artifact_types) { input_types.merge(output_types) }

    it 'uses the file extension of their type for its artifacts' do
      agent = agent_class.new
      expect(
        artifact_types.to_h do |artifact_name, _type|
          [artifact_name, File.extname(agent.artifact_ref(artifact_name))]
        end
      ).to eq(artifact_types.transform_values { |type| extension_by_type[type] })
    end
  end
end
