# Shared examples validating that the status displays the usage (cost and tokens) of a run, for the
# agents kinds publishing usage information during their runs (see
# XAeonAgents::Logger#status_usage_display).
#
# @param agent_class [Class] The agent class to be tested. It should be one of the test agents from
#   XAeonAgentsTest::Agents whose framework publishes usage information (ie. TestClineAgent or
#   TestAiAgent).
shared_examples 'a status displaying the usage of the run' do |agent_class|
  # Colored emojis expected in the status, per step status
  let(:status_emojis) do
    {
      executed: status_pastel.green('✓'),
      started: status_pastel.yellow('◌'),
      error: status_pastel.red('✗')
    }
  end

  # Suffix displayed in the status after the agent's name, ie. its full name without the name part.
  # It is specific to the agent kind (Cline agents display their provider and model, AiAgents agents
  # their model).
  let(:agent_status_suffix) do
    # Instantiate a probe agent just to compute its full name.
    # This agent is never run, so it does not appear in the displayed statuses.
    probe_agent = agent_class.new(name: 'status_test_probe')
    probe_agent.full_name.gsub('status_test_probe', '').strip
  end

  # Make sure agents instantiated by other examples don't pollute the displayed status
  before { XAeonAgents::AgentDefaults.root_agents = [] }

  it 'displays the tokens and cost usage of the run' do
    # Usage information published by the framework agents during real runs (see
    # ComposableAgents::AiAgents::Agent#track_llm_usage and the usage tracking of
    # ComposableAgents::Cline::Agent)
    usage = {
      cost: 2.5,
      input_tokens: 100_000,
      output_tokens: 50_000,
      cache_read_tokens: 0,
      cache_write_tokens: 0,
      context_tokens: 150_000,
      context_tokens_limit: 200_000
    }
    # The progress bar is filled at 7/10 (150K tokens used of a 200K context window)
    usage_progress_display = '150K tok [███████░░░] 200K'
    status_while_step_running = expected_status_string(
      [
        ["#{status_emojis[:started]} RootAgent", '$2.50', usage_progress_display, status_pastel.dim(agent_status_suffix)],
        ["#{status_emojis[:started]} └─ working_step", '', '', '']
      ]
    )
    status_when_executed = expected_status_string(
      [
        ["#{status_emojis[:executed]} RootAgent", '$2.50', usage_progress_display, status_pastel.dim(agent_status_suffix)],
        ["#{status_emojis[:executed]} └─ working_step", '', '', '']
      ]
    )

    with_tty_status do
      agent = agent_class.new(name: 'RootAgent')
      agent.run_proc = lambda do
        step(:working_step) do
          # Simulate the realtime usage tracking of the framework agents during their runs
          publish_usage(usage:)
          logger.info 'Usage has been tracked'
          expect_last_status_to_be(status_while_step_running)
        end
        expect_last_status_to_be(status_when_executed)
        @output_artifacts = {}
      end
      agent.run
    end
  end
end
