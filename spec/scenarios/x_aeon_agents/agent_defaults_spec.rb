require_relative 'shared_examples/agent_defaults'

describe XAeonAgents::AgentDefaults do
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
    expected_singleton_modules: [ComposableAgents::PromptRenderingStrategy::MarkdownHeavy]
  )

  # The AiAgents defaults
  it_behaves_like(
    'an agent using AgentDefaults',
    XAeonAgentsTest::Agents::TestAiAgent,
    configured_kwargs: { model: 'config-model' },
    expected_default_options: { strategy: ComposableAgents::PromptRenderingStrategy::Markdown },
    expected_default_options_kept: { strategy: ComposableAgents::PromptRenderingStrategy::Markdown },
    expected_singleton_modules: [ComposableAgents::PromptRenderingStrategy::Markdown]
  )

  describe 'normal agents' do
    # The normal Agents defaults
    it_behaves_like(
      'an agent using AgentDefaults',
      XAeonAgentsTest::Agents::TestAgent,
      configured_kwargs: { name: 'config-name' },
      expected_default_options: {},
      expected_default_options_kept: {}
    )

    describe 'validating status logging' do
      # Colored emojis expected in the status, per step status
      let(:status_emojis) do
        {
          executed: status_pastel.green('✓'),
          started: status_pastel.yellow('◌'),
          error: status_pastel.red('✗')
        }
      end

      # Make sure agents instantiated by other examples don't pollute the displayed status
      before { described_class.root_agents = [] }

      it 'displays the status of 1 root agent having 1 nested step' do
        status_while_outer_step_started = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ outer_step", '', '', '']
          ]
        )
        status_while_inner_step_started = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ outer_step", '', '', ''],
            ["#{status_emojis[:started]}    └─ inner_step", '', '', '']
          ]
        )
        # The nested step is executed before its parent, so both statuses are displayed at the same time
        status_when_inner_step_executed = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ outer_step", '', '', ''],
            ["#{status_emojis[:executed]}    └─ inner_step", '', '', '']
          ]
        )
        status_when_all_executed = expected_status_string(
          [
            ["#{status_emojis[:executed]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} └─ outer_step", '', '', ''],
            ["#{status_emojis[:executed]}    └─ inner_step", '', '', '']
          ]
        )

        with_tty_status do
          agent = XAeonAgentsTest::Agents::TestAgent.new(name: 'RootAgent')
          agent.run_proc = lambda do
            step(:outer_step) do
              logger.info 'Outer step is running'
              expect_last_status_to_be(status_while_outer_step_started)
              step(:inner_step) do
                logger.info 'Inner step is running'
                expect_last_status_to_be(status_while_inner_step_started)
              end
              expect_last_status_to_be(status_when_inner_step_executed)
            end
            expect_last_status_to_be(status_when_all_executed)
            @output_artifacts = {}
          end
          agent.run
          log_message('Agent has been run')
          expect_last_status_to_be(status_when_all_executed)
        end
      end

      it 'displays the status of 1 root agent having 1 nested step_agent' do
        status_while_sub_agent_runs = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ SubAgent", '', '', status_pastel.dim('(TestAgent)')]
          ]
        )
        status_when_sub_agent_executed = expected_status_string(
          [
            ["#{status_emojis[:executed]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} └─ SubAgent", '', '', status_pastel.dim('(TestAgent)')]
          ]
        )

        with_tty_status do
          root_agent = XAeonAgentsTest::Agents::TestAgent.new(name: 'RootAgent')
          # Instantiate the sub agent through the root agent, so that it is not a root agent itself
          sub_agent = root_agent.new_agent(XAeonAgentsTest::Agents::TestAgent, name: 'SubAgent')
          sub_agent.run_proc = lambda do
            step(:sub_step) do
              logger.info 'Sub agent step is running'
              expect_last_status_to_be(status_while_sub_agent_runs)
            end
            # The sub agent's step completion refreshes the status, still showing the started step_agent
            expect_last_status_to_be(status_while_sub_agent_runs)
            @output_artifacts = {}
          end
          root_agent.run_proc = lambda do
            step_agent(sub_agent)
            expect_last_status_to_be(status_when_sub_agent_executed)
            logger.info 'Sub agent has been run'
            expect_last_status_to_be(status_when_sub_agent_executed)
            @output_artifacts = {}
          end
          root_agent.run
          log_message('Agent has been run')
          expect_last_status_to_be(status_when_sub_agent_executed)
        end
      end

      it 'displays the status of 1 root agent having several nested steps with various statuses' do
        status_while_first_step_runs = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ first_step", '', '', '']
          ]
        )
        # The first step is executed while the second one is started
        status_with_various_statuses = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} ├─ first_step", '', '', ''],
            ["#{status_emojis[:started]} └─ parent_step", '', '', '']
          ]
        )
        status_when_error = expected_status_string(
          [
            ["#{status_emojis[:error]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} ├─ first_step", '', '', ''],
            ["#{status_emojis[:error]} └─ parent_step", '', '', ''],
            ["#{status_emojis[:error]}    └─ failing_step", '', '', '']
          ]
        )

        with_tty_status do
          agent = XAeonAgentsTest::Agents::TestAgent.new(name: 'RootAgent')
          agent.run_proc = lambda do
            step(:first_step) do
              logger.info 'First step is running'
              expect_last_status_to_be(status_while_first_step_runs)
            end
            step(:parent_step) do
              logger.info 'Parent step is running'
              expect_last_status_to_be(status_with_various_statuses)
              step(:failing_step) { raise 'Step has failed' }
            end
            @output_artifacts = {}
          end
          expect { agent.run }.to raise_error(RuntimeError, 'Step has failed')
          log_message('Agent has failed')
          expect_last_status_to_be(status_when_error)
        end
      end

      it 'displays the status of 1 root agent using task with a symbol and without a name' do
        status_while_task_started = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ symbol_task", '', '', '']
          ]
        )
        status_when_task_executed = expected_status_string(
          [
            ["#{status_emojis[:executed]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} └─ symbol_task", '', '', '']
          ]
        )

        with_tty_status do
          agent = XAeonAgentsTest::Agents::TestAgent.new(name: 'RootAgent')
          agent.run_proc = lambda do
            task(:symbol_task) do
              logger.info 'Symbol task is running'
              expect_last_status_to_be(status_while_task_started)
            end
            expect_last_status_to_be(status_when_task_executed)
            @output_artifacts = {}
          end
          agent.run
          log_message('Agent has been run')
          expect_last_status_to_be(status_when_task_executed)
        end
      end

      it 'displays the status of 1 root agent using task with a symbol and a name' do
        status_while_task_started = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ Named task", '', '', '']
          ]
        )
        status_when_task_executed = expected_status_string(
          [
            ["#{status_emojis[:executed]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} └─ Named task", '', '', '']
          ]
        )

        with_tty_status do
          agent = XAeonAgentsTest::Agents::TestAgent.new(name: 'RootAgent')
          agent.run_proc = lambda do
            task(:symbol_task, name: 'Named task') do
              logger.info 'Symbol task is running'
              expect_last_status_to_be(status_while_task_started)
            end
            expect_last_status_to_be(status_when_task_executed)
            @output_artifacts = {}
          end
          agent.run
          log_message('Agent has been run')
          expect_last_status_to_be(status_when_task_executed)
        end
      end

      it 'displays the status of 1 root agent using task with an agent and without a name' do
        status_while_sub_agent_task_runs = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ SubAgent", '', '', status_pastel.dim('(TestAgent)')]
          ]
        )
        status_when_sub_agent_task_executed = expected_status_string(
          [
            ["#{status_emojis[:executed]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} └─ SubAgent", '', '', status_pastel.dim('(TestAgent)')]
          ]
        )

        with_tty_status do
          root_agent = XAeonAgentsTest::Agents::TestAgent.new(name: 'RootAgent')
          # Instantiate the sub agent through the root agent, so that it is not a root agent itself
          sub_agent = root_agent.new_agent(XAeonAgentsTest::Agents::TestAgent, name: 'SubAgent')
          sub_agent.run_proc = lambda do
            logger.info 'Sub agent task is running'
            expect_last_status_to_be(status_while_sub_agent_task_runs)
            @output_artifacts = {}
          end
          root_agent.run_proc = lambda do
            # The task's name defaults to the agent's one
            task(sub_agent)
            expect_last_status_to_be(status_when_sub_agent_task_executed)
            @output_artifacts = {}
          end
          root_agent.run
          log_message('Agent has been run')
          expect_last_status_to_be(status_when_sub_agent_task_executed)
        end
      end

      it 'displays the status of 1 root agent using task with an agent and a name' do
        status_while_sub_agent_task_runs = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ Named agent task", '', '', status_pastel.dim('(TestAgent)')]
          ]
        )
        status_when_sub_agent_task_executed = expected_status_string(
          [
            ["#{status_emojis[:executed]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} └─ Named agent task", '', '', status_pastel.dim('(TestAgent)')]
          ]
        )

        with_tty_status do
          root_agent = XAeonAgentsTest::Agents::TestAgent.new(name: 'RootAgent')
          # Instantiate the sub agent through the root agent, so that it is not a root agent itself
          sub_agent = root_agent.new_agent(XAeonAgentsTest::Agents::TestAgent, name: 'SubAgent')
          sub_agent.run_proc = lambda do
            logger.info 'Sub agent task is running'
            expect_last_status_to_be(status_while_sub_agent_task_runs)
            @output_artifacts = {}
          end
          root_agent.run_proc = lambda do
            # The given name overrides the agent's one, while the agent's complement is still displayed
            task(sub_agent, name: 'Named agent task')
            expect_last_status_to_be(status_when_sub_agent_task_executed)
            @output_artifacts = {}
          end
          root_agent.run
          log_message('Agent has been run')
          expect_last_status_to_be(status_when_sub_agent_task_executed)
        end
      end

      it 'displays the status of 1 root agent using nested tasks with various statuses, names and symbols or agents' do
        status_while_first_task_runs = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:started]} └─ first_task", '', '', '']
          ]
        )
        # The first task is executed while the second one is started
        status_while_named_task_runs = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} ├─ first_task", '', '', ''],
            ["#{status_emojis[:started]} └─ Named task", '', '', '']
          ]
        )
        # The nested agent task is executed within the named task, before the failing one is started
        status_when_agent_task_executed = expected_status_string(
          [
            ["#{status_emojis[:started]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} ├─ first_task", '', '', ''],
            ["#{status_emojis[:started]} └─ Named task", '', '', ''],
            ["#{status_emojis[:executed]}    └─ agent_run_unnamed", '', '', status_pastel.dim('Unnamed (TestAgent)')]
          ]
        )
        status_when_error = expected_status_string(
          [
            ["#{status_emojis[:error]} RootAgent", '', '', status_pastel.dim('(TestAgent)')],
            ["#{status_emojis[:executed]} ├─ first_task", '', '', ''],
            ["#{status_emojis[:error]} └─ Named task", '', '', ''],
            ["#{status_emojis[:executed]}    ├─ agent_run_unnamed", '', '', status_pastel.dim('Unnamed (TestAgent)')],
            ["#{status_emojis[:error]}    └─ failing_task", '', '', '']
          ]
        )

        with_tty_status do
          agent = XAeonAgentsTest::Agents::TestAgent.new(name: 'RootAgent')
          # Instantiate the agent run by the nested agent task through the root agent, so that it is not a root agent itself
          unnamed_agent = agent.new_agent(XAeonAgentsTest::Agents::TestAgent)
          agent.run_proc = lambda do
            task(:first_task) do
              logger.info 'First task is running'
              expect_last_status_to_be(status_while_first_task_runs)
            end
            task(:named_task, name: 'Named task') do
              logger.info 'Named task is running'
              expect_last_status_to_be(status_while_named_task_runs)
              # The agent task's completion refreshes the status, still showing the started named task
              task(unnamed_agent)
              expect_last_status_to_be(status_when_agent_task_executed)
              task(:failing_task) { raise 'Task has failed' }
            end
            @output_artifacts = {}
          end
          expect { agent.run }.to raise_error(RuntimeError, 'Task has failed')
          log_message('Agent has failed')
          expect_last_status_to_be(status_when_error)
        end
      end
    end
  end
end
