describe XAeonAgents::Config do
  # Reset all public configuration state before each example, as the global
  # spec_helper around hook pre-populates some of it.
  before do
    described_class.instance_variable_set(:@secrets, nil)
    described_class.instance_variable_set(:@data_dir, nil)
    described_class.instance_variable_set(:@default_cline_cli_args, nil)
    described_class.instance_variable_set(:@debug, nil)
    described_class.instance_variable_set(:@agent_options, nil)
    XAeonAgents::Logger.debug = false
    ENV.delete('X_AEON_AGENTS_DEBUG')
    # Run the CLI through its public interface with stubbed AI agents: the lightweight
    # prompt command triggers the CLI initialization, which is what loads the config
    # files being tested here, without any actual AI call.
    stub_agent_run
  end

  # Writes optional global and project DSL config files in their real locations
  # and yields within the workspace. The global config lives in a mocked
  # Dir.home, the project one in the current directory (simulated via with_workspace).
  # A nil content means the file is not created.
  #
  # @param global_content [String, nil] Content of the global config file, or nil to not create it
  # @param project_content [String, nil] Content of the project config file, or nil to not create it
  def with_config_files(global_content: nil, project_content: nil, &)
    home_dir = temp_dir('home')
    allow(Dir).to receive(:home).and_return(home_dir)
    File.write(File.join(home_dir, '.x_aeon_agents.rb'), global_content) if global_content
    with_workspace do
      File.write('.x_aeon_agents.rb', project_content) if project_content
      yield
    end
  end

  # Whether the global config file should be created by the shared examples
  let(:create_global_config) { false }

  # Whether the project config file should be created by the shared examples
  let(:create_project_config) { false }

  shared_examples 'loading a config DSL file' do
    it 'loads the config file when no CLI flag is given' do
      with_config_files(
        global_content: create_global_config ? "debug true\n" : nil,
        project_content: create_project_config ? "debug true\n" : nil
      ) do
        run_cli 'prompt', 'test'
        expect(described_class.debug).to be true
      end
    end
  end

  shared_examples 'applying the debug CLI options' do
    it 'lets --debug override a config file that set debug false' do
      with_config_files(
        global_content: create_global_config ? "debug false\n" : nil,
        project_content: create_project_config ? "debug false\n" : nil
      ) do
        run_cli 'prompt', 'test', '--debug'
        expect(described_class.debug).to be true
      end
    end

    it 'lets --no-debug override a config file that set debug true' do
      with_config_files(
        global_content: create_global_config ? "debug true\n" : nil,
        project_content: create_project_config ? "debug true\n" : nil
      ) do
        run_cli 'prompt', 'test', '--no-debug'
        expect(described_class.debug).to be false
      end
    end
  end

  describe 'without any DSL config file' do
    describe '#data_dir' do
      it 'returns the default data directory when not configured' do
        expect(described_class.data_dir).to eq '.x_aeon_agents'
      end

      it 'returns the configured data directory' do
        described_class.data_dir = '/tmp/my_data'
        expect(described_class.data_dir).to eq '/tmp/my_data'
      end
    end

    describe '#default_cline_cli_args' do
      it 'returns the default Cline CLI arguments when not configured' do
        expect(described_class.default_cline_cli_args).to eq(thinking: 'xhigh')
      end

      it 'returns the configured Cline CLI arguments' do
        described_class.default_cline_cli_args = { thinking: 'low', model: 'gpt' }
        expect(described_class.default_cline_cli_args).to eq(thinking: 'low', model: 'gpt')
      end
    end

    describe '#debug' do
      it 'returns false by default' do
        expect(described_class.debug).to be false
      end

      it 'returns true when explicitly enabled' do
        described_class.debug = true
        expect(described_class.debug).to be true
      end

      it 'returns the value from the X_AEON_AGENTS_DEBUG ENV variable' do
        ENV['X_AEON_AGENTS_DEBUG'] = '1'
        expect(described_class.debug).to be true
      ensure
        ENV.delete('X_AEON_AGENTS_DEBUG')
      end

      it 'propagates the debug value to the Logger' do
        described_class.debug = true
        expect(XAeonAgents::Logger.debug).to be true
      end
    end

    describe 'secret accessors' do
      %i[cline_api_key openrouter_api_key github_token].each do |secret_name|
        describe "##{secret_name}" do
          let(:env_name) { secret_name.to_s.upcase }

          it 'returns the configured secret' do
            described_class.send(:"#{secret_name}=", 'my-secret')
            expect(described_class.send(secret_name)).to eq 'my-secret'
          end

          it 'falls back to the ENV variable when not configured' do
            ENV[env_name] = 'env-secret'
            expect(described_class.send(secret_name)).to eq 'env-secret'
          ensure
            ENV.delete(env_name)
          end

          it 'falls back to the launcher keys when neither configured nor in ENV' do
            allow(XAeonAgents::Helpers).to receive(:keys_from_launcher)
              .and_return(secret_name => SecretString.new('launcher-secret'))
            expect(described_class.send(secret_name)).to eq 'launcher-secret'
          end

          it 'returns nil when no secret is available' do
            allow(XAeonAgents::Helpers).to receive(:keys_from_launcher).and_return({})
            expect(described_class.send(secret_name)).to be_nil
          end
        end
      end
    end

    describe '#agent_options' do
      it 'allows reading default agent options' do
        expect(described_class.agent_options['free_simple']).to eq(
          model: 'openrouter/free',
          strategy: ComposableAgents::PromptRenderingStrategy::Markdown
        )
      end

      it 'allows writing new agent options' do
        described_class.agent_options['custom_category'] = { model: 'gpt-4' }
        expect(described_class.agent_options['custom_category']).to eq(model: 'gpt-4')
      end

      it 'allows writing agent options that are lazily evaluated and memoized' do
        nbr_evaluations = 0
        described_class.agent_options['custom_category'] = proc do
          nbr_evaluations += 1
          { model: 'gpt-4' }
        end
        expect(described_class.agent_options['custom_category']).to eq(model: 'gpt-4')
        expect(described_class.agent_options['custom_category']).to eq(model: 'gpt-4')
        expect(described_class.agent_options['custom_category']).to eq(model: 'gpt-4')
        expect(nbr_evaluations).to eq 1
      end

      it 'allows overwriting default agent options' do
        described_class.agent_options['free_simple'] = { model: 'custom-model' }
        expect(described_class.agent_options['free_simple']).to eq(model: 'custom-model')
      end

      it 'lazily evaluates proc-based options at read time' do
        options = described_class.agent_options
        described_class.cline_api_key = 'lazy-eval-key'
        expect(options['free_complex'][:api_key]).to eq 'lazy-eval-key'
      end
    end

    describe '#configure' do
      it 'sets multiple configuration properties at once' do
        described_class.configure(
          data_dir: '/tmp/cfg',
          default_cline_cli_args: { thinking: 'medium' },
          cline_api_key: 'cfg-secret',
          debug: true
        )
        expect(described_class.data_dir).to eq '/tmp/cfg'
        expect(described_class.default_cline_cli_args).to eq(thinking: 'medium')
        expect(described_class.cline_api_key).to eq 'cfg-secret'
        expect(described_class.debug).to be true
      end

      it 'propagates the debug value to the Logger' do
        described_class.configure(debug: true)
        expect(XAeonAgents::Logger.debug).to be true
      end
    end

    it 'does nothing when no config file exists' do
      with_config_files do
        run_cli 'prompt', 'test'
        expect(described_class.debug).to be false
      end
    end
  end

  describe 'with only a global DSL config file' do
    let(:create_global_config) { true }

    it_behaves_like 'loading a config DSL file'
    it_behaves_like 'applying the debug CLI options'
  end

  describe 'with only a project DSL config file' do
    let(:create_project_config) { true }

    it_behaves_like 'loading a config DSL file'
    it_behaves_like 'applying the debug CLI options'

    it 'uses the real config paths from the current directory' do
      with_config_files(project_content: "debug true\n") do
        expect(described_class.config_paths.last).to eq File.join(Dir.pwd, '.x_aeon_agents.rb')
        run_cli 'prompt', 'test'
        expect(described_class.debug).to be true
      end
    end
  end

  describe 'with both global and project DSL config files' do
    let(:create_global_config) { true }
    let(:create_project_config) { true }

    it_behaves_like 'applying the debug CLI options'

    it 'lets the project DSL file override the global DSL file' do
      with_config_files(global_content: "debug true\n", project_content: "debug false\n") do
        run_cli 'prompt', 'test'
        expect(described_class.debug).to be false
      end
    end
  end
end
