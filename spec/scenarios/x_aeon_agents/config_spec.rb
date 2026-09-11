describe XAeonAgents::Config do
  # Reset all public configuration state before each example, as the global
  # spec_helper around hook pre-populates some of it.
  before do
    described_class.instance_variable_set(:@secrets, nil)
    described_class.instance_variable_set(:@secret_procs, nil)
    described_class.instance_variable_set(:@data_dir, nil)
    described_class.instance_variable_set(:@default_cline_cli_args, nil)
    described_class.instance_variable_set(:@debug, nil)
    described_class.instance_variable_set(:@logger, nil)
    ENV.delete('X_AEON_AGENTS_DEBUG')
    # Run the CLI through its public interface with stubbed AI agents: the lightweight
    # prompt command triggers the CLI initialization, which is what loads the config
    # files being tested here, without any actual AI call.
    stub_agent_run
  end

  # Writes optional global, project and env-var designated DSL config files in
  # their real locations and yields within the workspace. The global config
  # lives in a mocked Dir.home, the project one in the current directory
  # (simulated via with_workspace), and the env-var one in a temporary directory
  # referenced by the X_AEON_AGENTS_CONFIG environment variable. A nil content
  # means the file is not created.
  #
  # @param global_content [String, nil] Content of the global config file, or nil to not create it
  # @param project_content [String, nil] Content of the project config file, or nil to not create it
  # @param env_content [String, nil] Content of the config file designated by the X_AEON_AGENTS_CONFIG env var, or nil to not create it
  def with_config_files(global_content: nil, project_content: nil, env_content: nil, &)
    home_dir = temp_dir('home')
    allow(Dir).to receive(:home).and_return(home_dir)
    File.write(File.join(home_dir, '.x_aeon_agents.rb'), global_content) if global_content
    env_config_path = File.expand_path('.x_aeon_agents_test/env_config/.x_aeon_agents.rb')
    FileUtils.mkdir_p(File.dirname(env_config_path))
    File.write(env_config_path, env_content) if env_content
    begin
      with_workspace do
        File.write('.x_aeon_agents.rb', project_content) if project_content
        ENV['X_AEON_AGENTS_CONFIG'] = env_config_path if env_content
        yield
      end
    ensure
      ENV.delete('X_AEON_AGENTS_CONFIG')
    end
  end

  # Whether the global config file should be created by the shared examples
  let(:create_global_config) { false }

  # Whether the project config file should be created by the shared examples
  let(:create_project_config) { false }

  # Shared examples validating that a secret is retrieved through its dedicated config
  # DSL method: the retrieval code defined in the config file is evaluated lazily when
  # the secret is read, and its result is memoized.
  shared_examples 'a secret retrievable through the config DSL' do |secret_name|
    it "retrieves #{secret_name} using the code defined in the config DSL" do
      with_config_files(
        project_content: <<~CONFIG
          #{secret_name} do
            'dsl-secret'
          end
        CONFIG
      ) do
        run_cli 'prompt', 'test'
        expect(described_class.send(secret_name)).to eq 'dsl-secret'
      end
    end

    it "evaluates the #{secret_name} retrieval code only when needed and memoizes its result" do
      with_config_files(
        project_content: <<~CONFIG
          #{secret_name} do
            File.write('retrieval_counter.txt', (File.exist?('retrieval_counter.txt') ? File.read('retrieval_counter.txt').to_i : 0) + 1)
            'lazy-secret'
          end
        CONFIG
      ) do
        run_cli 'prompt', 'test'
        expect(described_class.send(secret_name)).to eq 'lazy-secret'
        expect(described_class.send(secret_name)).to eq 'lazy-secret'
        expect(File.read('retrieval_counter.txt')).to eq '1'
      end
    end
  end

  # Shared examples validating that a secret is retrieved when the config DSL block
  # returns a SecretString directly (instead of a plain String). The config code must
  # keep the already-protected value untouched (not re-wrap it), so the accessor still
  # exposes the underlying unprotected String.
  shared_examples 'a secret provided directly as a SecretString through the config DSL' do |secret_name|
    it "retrieves #{secret_name} using the code defined in the config DSL when it returns a SecretString" do
      with_config_files(
        project_content: <<~CONFIG
          #{secret_name} do
            SecretString.new('dsl-secret')
          end
        CONFIG
      ) do
        run_cli 'prompt', 'test'
        expect(described_class.send(secret_name)).to eq 'dsl-secret'
      end
    end

    it "exposes the #{secret_name} SecretString as an unprotected String without re-wrapping it" do
      with_config_files(
        project_content: <<~CONFIG
          #{secret_name} do
            SecretString.new('dsl-secret')
          end
        CONFIG
      ) do
        run_cli 'prompt', 'test'
        value = described_class.send(secret_name)
        # The accessor returns the unprotected String (via SecretString#to_unprotected),
        # not the SecretString object itself nor a doubly-wrapped SecretString.
        expect(value).to be_a(String)
        expect(value).to eq 'dsl-secret'
        # The memoized stored value is the SecretString returned by the DSL, kept as-is.
        stored = described_class.instance_variable_get(:@secrets)[secret_name]
        expect(stored).to be_a(SecretString)
        expect(stored.to_unprotected).to eq 'dsl-secret'
      end
    end

    it "evaluates the #{secret_name} retrieval code returning a SecretString only when needed and memoizes its result" do
      with_config_files(
        project_content: <<~CONFIG
          #{secret_name} do
            File.write('retrieval_counter.txt', (File.exist?('retrieval_counter.txt') ? File.read('retrieval_counter.txt').to_i : 0) + 1)
            SecretString.new('lazy-secret')
          end
        CONFIG
      ) do
        run_cli 'prompt', 'test'
        expect(described_class.send(secret_name)).to eq 'lazy-secret'
        expect(described_class.send(secret_name)).to eq 'lazy-secret'
        expect(File.read('retrieval_counter.txt')).to eq '1'
      end
    end
  end

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

  describe 'with a config DSL declaring secret retrieval' do
    XAeonAgents::Config::KNOWN_SECRETS.each do |secret_name|
      describe "##{secret_name}" do
        it_behaves_like 'a secret retrievable through the config DSL', secret_name
        it_behaves_like 'a secret provided directly as a SecretString through the config DSL', secret_name
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
        expect(described_class.logger.debug?).to be true
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

          it 'returns nil when no secret is available' do
            expect(described_class.send(secret_name)).to be_nil
          end
        end
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
        expect(described_class.logger.debug?).to be true
      end
    end

    it 'does nothing when no config file exists' do
      with_config_files do
        run_cli 'prompt', 'test'
        expect(described_class.debug).to be false
      end
    end
  end

  describe '#test_project_cmd' do
    it 'returns nil when no config file defines a tests command' do
      with_config_files do
        run_cli 'prompt', 'test'
        expect(described_class.test_project_cmd).to be_nil
      end
    end

    it 'returns the command line defined in the config DSL' do
      with_config_files(
        project_content: <<~CONFIG
          test_project_cmd 'bundle exec rspec'
        CONFIG
      ) do
        run_cli 'prompt', 'test'
        expect(described_class.test_project_cmd).to eq 'bundle exec rspec'
      end
    end
  end

  describe '#data_dir' do
    it 'returns the default data directory when no config file defines it' do
      with_config_files do
        run_cli 'prompt', 'test'
        expect(described_class.data_dir).to eq '.x_aeon_agents'
      end
    end

    it 'returns the data directory defined in the config DSL' do
      with_config_files(
        project_content: <<~CONFIG
          data_dir 'my_data_dir'
        CONFIG
      ) do
        run_cli 'prompt', 'test'
        expect(described_class.data_dir).to eq 'my_data_dir'
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

  describe 'with an X_AEON_AGENTS_CONFIG env var designating a DSL config file' do
    it 'loads the config file designated by the env var' do
      with_config_files(env_content: "debug true\n") do
        expect(described_class.config_paths.last).to eq ENV.fetch('X_AEON_AGENTS_CONFIG')
        run_cli 'prompt', 'test'
        expect(described_class.debug).to be true
      end
    end

    it 'lets the env-var designated config file override the global and project config files' do
      with_config_files(
        global_content: "debug true\n",
        project_content: "debug true\n",
        env_content: "debug false\n"
      ) do
        run_cli 'prompt', 'test'
        expect(described_class.debug).to be false
      end
    end

    it 'still loads the global config file when the env var designates a non-existing path' do
      with_config_files(global_content: "debug true\n") do
        with_env_var('X_AEON_AGENTS_CONFIG', File.expand_path('non_existing/.x_aeon_agents.rb')) do
          run_cli 'prompt', 'test'
          expect(described_class.debug).to be true
        end
      end
    end
  end
end
