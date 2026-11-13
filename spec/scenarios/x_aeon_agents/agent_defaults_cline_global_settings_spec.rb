describe XAeonAgents::AgentDefaults do
  describe 'Cline agents global settings' do
    # Cline tools expected to be disabled by default in all Cline agents.
    # These tools are not used by X-Aeon agents: agents are orchestrated by ComposableAgents.
    let(:default_disabled_tools) do
      %w[
        spawn_agent
        team_attach_outcome_fragment
        team_await_runs
        team_broadcast
        team_cancel_run
        team_cleanup
        team_create_outcome
        team_finalize_outcome
        team_list_outcomes
        team_list_runs
        team_mission_log
        team_read_mailbox
        team_review_outcome_fragment
        team_run_task
        team_send_message
        team_shutdown_teammate
        team_spawn_teammate
        team_status
        team_task
        teams
      ]
    end

    # Get the Cline global settings resulting from the defaults applied to a Cline agent.
    #
    # @return [Cline::GlobalSettings] The Cline global settings configured by the agent's defaults
    def agent_global_settings
      global_settings = Cline::GlobalSettings.new
      XAeonAgentsTest::Agents::TestClineAgent.new.received_kwargs[:configure_global].call(global_settings)
      global_settings
    end

    it 'disables the Cline tools that are not used by agents' do
      expect(agent_global_settings.disabled_tools.to_a).to match_array(default_disabled_tools)
    end

    it 'does not disable ask_question when interactive mode is enabled' do
      XAeonAgents::Config.interactive = true

      expect(agent_global_settings.disabled_tools.to_a).not_to include('ask_question')
    end

    it 'disables ask_question when interactive mode is disabled' do
      XAeonAgents::Config.interactive = false

      expect(agent_global_settings.disabled_tools.to_a).to include('ask_question')
    end

    it 'merges the tools disabled by the config DSL with the default ones, without duplicates' do
      XAeonAgents::ConfigDsl.new.evaluate <<~CONFIG
        configure_agent(:TestClineAgent) do
          {
            configure_global: proc do |global_settings|
              global_settings.disabled_tools = %w[editor run_commands #{default_disabled_tools.first}]
            end
          }
        end
      CONFIG

      expect(agent_global_settings.disabled_tools.to_a).to contain_exactly(
        'editor',
        'run_commands',
        *default_disabled_tools
      )
    end
  end
end
