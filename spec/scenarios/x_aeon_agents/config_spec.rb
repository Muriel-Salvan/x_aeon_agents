describe XAeonAgents::Config do
  # Reset all public configuration state before each example, as the global
  # spec_helper around hook pre-populates some of it.
  before do
    described_class.instance_variable_set(:@secrets, nil)
    described_class.instance_variable_set(:@data_dir, nil)
    described_class.instance_variable_set(:@default_cline_cli_args, nil)
    described_class.instance_variable_set(:@debug, nil)
    XAeonAgents::Logger.debug = false
  end

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
end
