describe XAeonAgents::Helpers do
  describe 'repository prompts' do
    it 'tells in which repository agents are working, and restricts them to read it' do
      with_workspace do
        expect(described_class.repository_access_system_instructions).to eq(
          "The current repository in which you are working is `#{Dir.pwd}`."
        )
        expect(described_class.repository_access_constraint).to eq(
          "You should only read files that are part of the current repository: `#{Dir.pwd}`"
        )
      end
    end

    it 'allows agents to write in the repository when they are writable' do
      with_workspace do
        expect(described_class.repository_access_constraint(writable: true)).to eq(
          "You should only read and write files that are part of the current repository: `#{Dir.pwd}`"
        )
      end
    end
  end
end
