require_relative 'shared_examples/agent_defaults'
require_relative 'shared_examples/status_usage'

describe XAeonAgents::AgentDefaults do
  describe 'Cline agents' do
    # The Cline agents defaults
    it_behaves_like(
      'an agent using AgentDefaults',
      XAeonAgentsTest::Agents::TestClineAgent,
      configured_kwargs: {
        model: 'config-model',
        cli_options: { thinking: 'low' }
      },
      expected_default_options: {
        api_key: 'test-cline-api-key',
        cli_options: { thinking: 'xhigh' }
      },
      expected_default_options_kept: { api_key: 'test-cline-api-key' },
      expected_singleton_modules: [ComposableAgents::PromptRenderingStrategy::MarkdownHeavyFiles]
    )

    it_behaves_like(
      'a status displaying the usage of the run',
      XAeonAgentsTest::Agents::TestClineAgent
    )

    it 'gives each agent run its own artifacts directory' do
      agent = XAeonAgentsTest::Agents::TestClineAgent.new(session_id: 'test-session')
      expect(agent.artifacts_directory).to eq(
        "#{XAeonAgents::Config.data_dir}/sessions/test-session/composable_agents/runs/test-session-TestClineAgent/artifacts"
      )
    end

    it 'writes artifacts in the directory of the agent run, using the file format of their type' do
      agent = XAeonAgentsTest::Agents::TestClineArtifactsAgent.new(session_id: 'test-session')
      run_dir = "#{XAeonAgents::Config.data_dir}/sessions/test-session/composable_agents/runs/test-session-TestClineArtifactsAgent"

      output_artifacts = agent.run(
        markdown_input: "# Input artifact\n",
        text_input: "Input artifact text\n",
        json_input: { 'input' => true }
      )

      # Input artifacts are given to the agent as files having the file extension of their type
      expect(agent.received_prompts.join("\n")).to include(
        "`#{run_dir}/artifacts/input/markdown_input.md`",
        "`#{run_dir}/artifacts/input/text_input.txt`",
        "`#{run_dir}/artifacts/input/json_input.json`"
      )
      # Output artifacts are written to, and read back from, files having the file extension of their type
      expect(output_artifacts).to eq(
        markdown_artifact: "# Written Markdown artifact\n",
        text_artifact: "Written text artifact\n",
        json_artifact: { 'written' => true }
      )
      expect(File.read("#{run_dir}/artifacts/output/markdown_artifact.md")).to eq "# Written Markdown artifact\n"
      expect(File.read("#{run_dir}/artifacts/output/text_artifact.txt")).to eq "Written text artifact\n"
      expect(JSON.parse(File.read("#{run_dir}/artifacts/output/json_artifact.json"))).to eq('written' => true)
      # Artifacts are not written in the directory shared by all the agents of the session
      expect(File).not_to exist("#{XAeonAgents::Config.data_dir}/sessions/test-session/composable_agents/artifacts")
    end
  end
end
