# Shared examples validating the common behavior of all agents using the AgentDefaults mixin:
# framework defaults application, default session properties, and config DSL overwriting of defaults.
#
# @param agent_class [Class] The agent class to be tested. It should be one of the test agents from
#   XAeonAgentsTest::Agents (ie. an agent prepending AgentDefaults and including
#   XAeonAgentsTest::Agents::Spy), so that its constructor kwargs can be spied upon.
# @param configured_kwargs [Hash{Symbol => Object}] The kwargs to be configured through the config
#   DSL (using the configure_agent method of the .x_aeon_agents.rb config files), expected to
#   overwrite the framework defaults. Values must be literals that can be embedded in the
#   generated config file content.
# @param expected_default_options [Hash{Symbol => Object}] The framework defaults expected to be applied
#   by the AgentDefaults mixin, per constructor kwarg name. Empty if the agent kind gets no
#   framework default.
# @param expected_default_options_kept [Hash{Symbol => Object}] The framework defaults that are not overwritten by
#   the config DSL, expected to still be applied.
# @param configurable_kwarg [Symbol, nil] The kwarg used to validate the config DSL behaviors
#   needing a single kwarg (several configure_agent calls, configs of other agent classes). If nil
#   (default), the first one of configured_kwargs is used.
# @param expected_singleton_modules [Array<Module>] The modules expected to be included in the
#   agent's singleton class after instantiation (eg. the prompt rendering strategies applied by
#   the AgentDefaults mixin or by the agent's framework class).
shared_examples 'an agent using AgentDefaults' do |
  agent_class,
  configured_kwargs:,
  expected_default_options:,
  expected_default_options_kept:,
  configurable_kwarg: nil,
  expected_singleton_modules: []
|
  # Name of the tested agent class, as used by the config DSL
  let(:agent_class_name) { agent_class.name.split('::').last }

  # Kwarg used to validate the config DSL behaviors needing a single kwarg
  let(:tested_configurable_kwarg) { configurable_kwarg || configured_kwargs.keys.first }

  describe "testing agent class #{agent_class}" do
    describe 'validating initialization' do
      it 'gives default options' do
        agent = agent_class.new
        expected_default_options.each do |kwargs_name, expected_value|
          expect(agent.received_kwargs[kwargs_name]).to eq expected_value
        end
        expected_singleton_modules.each do |expected_module|
          expect(agent.singleton_class.include?(expected_module)).to be true
        end
      end

      it 'sets dedicated session properties' do
        agent = agent_class.new
        session_dir_regexp = %r{^#{Regexp.escape(XAeonAgents::Config.data_dir)}/sessions/([^/]+)/composable_agents$}
        expect(agent.received_kwargs[:composable_agents_dir]).to match session_dir_regexp
        expect(agent.run_id).to eq "#{agent.received_kwargs[:composable_agents_dir].match(session_dir_regexp)[1]}-#{agent_class_name}"
      end

      it 'lets the config DSL overwrite the default options' do
        XAeonAgents::ConfigDsl.new.evaluate <<~CONFIG
          configure_agent(:#{agent_class_name}) do
            {
              #{configured_kwargs.map { |kwargs_name, value| "#{kwargs_name}: #{value.inspect}" }.join(",\n  ")}
            }
          end
        CONFIG
        agent = agent_class.new
        configured_kwargs.each do |kwargs_name, expected_value|
          expect(agent.received_kwargs[kwargs_name]).to eq expected_value
        end
        # Defaults not overwritten by the config DSL are still applied
        expected_default_options_kept.each do |kwargs_name, expected_value|
          expect(agent.received_kwargs[kwargs_name]).to eq expected_value
        end
      end

      it 'lets several configure_agent calls read and modify the configured options' do
        XAeonAgents::ConfigDsl.new.evaluate <<~CONFIG
          configure_agent(:#{agent_class_name}) do
            { #{tested_configurable_kwarg}: 'initial' }
          end
          configure_agent(:#{agent_class_name}) do |agent_config|
            agent_config[:#{tested_configurable_kwarg}] = "\#{agent_config[:#{tested_configurable_kwarg}]} modified"
            agent_config
          end
        CONFIG
        expect(agent_class.new.received_kwargs[tested_configurable_kwarg]).to eq 'initial modified'
      end

      it 'lets explicitly given kwargs take precedence over the configured ones' do
        XAeonAgents::ConfigDsl.new.evaluate <<~CONFIG
          configure_agent(:#{agent_class_name}) do
            { #{tested_configurable_kwarg}: 'from-config' }
          end
        CONFIG
        expect(agent_class.new(tested_configurable_kwarg => 'explicit').received_kwargs[tested_configurable_kwarg]).to eq 'explicit'
      end

      it 'ignores configure_agent calls for other agent classes' do
        XAeonAgents::ConfigDsl.new.evaluate <<~CONFIG
          configure_agent(:SomeOtherAgent) do
            { #{tested_configurable_kwarg}: 'should-not-apply' }
          end
        CONFIG
        expect(agent_class.new.received_kwargs[tested_configurable_kwarg]).not_to eq 'should-not-apply'
      end
    end

    describe 'validating status logging' do
      # Suffix displayed in the status after an agent's name, ie. its full name without the name part
      let(:agent_status_suffix) do
        # Instantiate a probe agent just to compute its full name, as it is specific to the agent kind
        # (plain agents display their class, AI agents their model, Cline agents their model...).
        # This agent is never run, so it does not appear in the displayed statuses.
        probe_agent = agent_class.new(name: 'status_test_probe')
        probe_agent.full_name.gsub('status_test_probe', '').strip
      end

      # Status displayed in front of a root agent having no recorded step: it has no status, so it
      # is displayed with the unknown status emoji, dimmed.
      let(:unknown_status) { status_pastel.dim('·') }

      # Colored emojis expected in the status, per step status
      let(:status_emojis) do
        {
          executed: status_pastel.green('✓'),
          started: status_pastel.yellow('◌'),
          error: status_pastel.red('✗')
        }
      end

      # Make sure agents instantiated by other examples don't pollute the displayed status
      before { XAeonAgents::AgentDefaults.root_agents = [] }

      it 'displays the full status of 1 root agent' do
        status_of_single_root_agent = expected_status_string(
          [
            ["#{unknown_status} RootAgent", '', '', status_pastel.dim(agent_status_suffix)]
          ]
        )

        with_tty_status do
          agent = agent_class.new(name: 'RootAgent')
          agent.run
          expect_last_status_to_be(status_of_single_root_agent)
        end
      end

      it 'displays the status of 1 root agent with several runs' do
        # While there is only 1 run, the root agent is not numbered in the status
        status_of_first_run = expected_status_string(
          [
            ["#{unknown_status} RootAgent", '', '', status_pastel.dim(agent_status_suffix)]
          ]
        )
        status_of_all_runs = expected_status_string(
          [
            ["#{unknown_status} RootAgent (run #0)", '', '', status_pastel.dim(agent_status_suffix)],
            ["#{unknown_status} RootAgent (run #1)", '', '', status_pastel.dim(agent_status_suffix)]
          ]
        )

        with_tty_status do
          agent = agent_class.new(name: 'RootAgent')
          agent.run
          expect_last_status_to_be(status_of_first_run)
          agent.run
          expect_last_status_to_be(status_of_all_runs)
        end
      end

      it 'displays the status of several root agents' do
        status_of_first_agent = expected_status_string(
          [
            ["#{unknown_status} Agent1", '', '', status_pastel.dim(agent_status_suffix)]
          ]
        )
        status_of_all_agents = expected_status_string(
          [
            ["#{unknown_status} Agent1", '', '', status_pastel.dim(agent_status_suffix)],
            ["#{unknown_status} Agent2", '', '', status_pastel.dim(agent_status_suffix)]
          ]
        )

        with_tty_status do
          agent1 = agent_class.new(name: 'Agent1')
          agent1.run
          expect_last_status_to_be(status_of_first_agent)
          agent2 = agent_class.new(name: 'Agent2')
          agent2.run
          expect_last_status_to_be(status_of_all_agents)
        end
      end

      it 'displays the status of an agent without name' do
        # The agent's full name is displayed as the name complement, as there is no name to strip
        status_of_unnamed_agent = expected_status_string(
          [
            ["#{unknown_status} ", '', '', status_pastel.dim("Unnamed #{agent_status_suffix}")]
          ]
        )

        with_tty_status do
          agent = agent_class.new
          agent.run
          expect_last_status_to_be(status_of_unnamed_agent)
        end
      end

      it 'truncates the status lines to the screen width' do
        # The status row (status emoji, space, 130-character agent name and the agent's complement)
        # exceeds the screen width (120 columns): it is truncated to 119 visible characters, so that
        # it always fits on exactly 1 row, and the cut colored segment is properly closed.
        expected_truncated_status = "#{unknown_status} #{'A' * 117}\e[0m"

        with_tty_status do
          agent = agent_class.new(name: 'A' * 130)
          agent.run
          expect_last_status_to_be(expected_truncated_status)
        end
      end

      it 'degrades to plain sequential output when the status does not fit on the screen' do
        status_while_third_step_started = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim(agent_status_suffix)],
            ["#{status_emojis[:executed]} ├─ first_step", '', '', ''],
            ["#{status_emojis[:executed]} ├─ second_step", '', '', ''],
            ["#{status_emojis[:started]} └─ third_step", '', '', '']
          ]
        )
        status_when_all_executed = expected_status_string(
          [
            ["#{status_emojis[:executed]} RootAgent", '', '', status_pastel.dim(agent_status_suffix)],
            ["#{status_emojis[:executed]} ├─ first_step", '', '', ''],
            ["#{status_emojis[:executed]} ├─ second_step", '', '', ''],
            ["#{status_emojis[:executed]} └─ third_step", '', '', '']
          ]
        )

        with_tty_status(screen_height: 5) do
          agent = agent_class.new(name: 'RootAgent')
          agent.run_proc = lambda do
            step(:first_step) { logger.info 'First step is running' }
            step(:second_step) { logger.info 'Second step is running' }
            step(:third_step) do
              logger.info 'Third step is running'
              # The status (4 rows) cannot fit on the 5-row screen with the log line above it: the
              # status is still displayed, but in degraded plain sequential output.
              expect_last_status_to_be(status_while_third_step_started)
            end
            expect_last_status_to_be(status_when_all_executed)
            @output_artifacts = {}
          end
          agent.run
          log_message('Agent has been run')
          expect_last_status_to_be(status_when_all_executed)
          # From the first degraded status onward, the output is plain sequential: each log line is
          # followed by a blank line and the full status, without any cursor manipulation, as the
          # display bookkeeping has been reset.
          raw_output = tty_screen_raw_output
          first_degraded_index = raw_output.index(status_while_third_step_started)
          degraded_output = raw_output[first_degraded_index..]
          expect(degraded_output).not_to match(/\e\[\d*[A-L]/)
          expect(degraded_output).to end_with(
            "#{XAeonAgents::Logger::LINE_SEPARATOR * 2}#{status_when_all_executed}#{XAeonAgents::Logger::LINE_SEPARATOR}"
          )
        end
      end
    end
  end
end
