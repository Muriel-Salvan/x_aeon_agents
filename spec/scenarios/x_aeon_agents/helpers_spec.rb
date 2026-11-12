describe XAeonAgents::Helpers do
  describe 'repository prompts' do
    it 'tells in which repository agents are working, and restricts them to read it' do
      with_workspace do
        expect(described_class.repository_access_system_instructions).to eq(
          "The current repository in which you are working is `#{Dir.pwd}`."
        )
        expect(described_class.repository_access_constraint).to eq(
          "- You should only read files that are part of the current repository: `#{Dir.pwd}`"
        )
      end
    end

    it 'allows agents to write in the repository when they are writable' do
      with_workspace do
        expect(described_class.repository_access_constraint(writable: true)).to eq(
          "- You should only read and write files that are part of the current repository: `#{Dir.pwd}`"
        )
      end
    end
  end

  describe 'artifact prompts' do
    it 'allows agents to access their artifact files' do
      with_workspace do
        expect(described_class.artifacts_access_constraint('/tmp/a.md', '/tmp/b.md')).to eq(
          '- You are allowed to read and write the artifact files at `/tmp/a.md`, `/tmp/b.md`, ' \
            'even if they are not part of the current repository'
        )
      end
    end

    it 'returns nil when no artifact path is given' do
      expect(described_class.artifacts_access_constraint).to be_nil
    end
  end

  describe 'non-interactive prompts' do
    it 'forbids the ask_question tool when the interactive mode is disabled' do
      XAeonAgents::Config.interactive = false
      expect(described_class.non_interactive_constraint).to eq(
        '- You MUST NOT use the ask_question tool under any circumstances: ' \
          'you are running in non-interactive mode with no human user available, ' \
          'so proceed using your best judgment without asking'
      )
    end

    it 'returns nil when the interactive mode is enabled' do
      XAeonAgents::Config.interactive = true
      expect(described_class.non_interactive_constraint).to be_nil
    end
  end
end
