describe XAeonAgents::Agents::DeveloperAgent do
  describe 'reusing sessions' do
    before do
      coder_revision = 0
      stub_agent_run(
        stub_handler: lambda { |agent, **kwargs|
          case agent
          when XAeonAgents::Agents::PlanGeneratorAgent
            { plan: "Detailed step-by-step plan for requirements \"#{kwargs[:requirements]}\"" }
          when XAeonAgents::Agents::CoderAgent
            coder_revision += 1
            File.write('new_feature.rb', "puts 'Feature revision #{coder_revision}'\n")
            {}
          when XAeonAgents::Agents::DocumenterAgent
            File.write('README.md', "# Doc revision #{coder_revision}\n")
            {}
          else
            {}
          end
        }
      )
      stub_review_content
    end

    it 'reuses session to keep old CoderAgent output and uses a new session for fresh output' do
      with_git_workspace(files: { 'test.txt' => "original\n" }) do
        # First run with session A - CoderAgent writes initial content (revision 1)
        described_class.new(session_id: 'session-a', commit: false, pull_request: false).run(requirements: 'Add a new feature')
        expect(File.read('new_feature.rb')).to eq("puts 'Feature revision 1'\n")
        expect(File.read('README.md')).to eq("# Doc revision 1\n")

        # Second run with same session A - session is reused, CoderAgent is skipped,
        # so the files still have the old content from the first run
        described_class.new(session_id: 'session-a', commit: false, pull_request: false).run(requirements: 'Add a new feature')
        expect(File.read('new_feature.rb')).to eq("puts 'Feature revision 1'\n")
        expect(File.read('README.md')).to eq("# Doc revision 1\n")

        # Third run with different session B - fresh session, CoderAgent produces new content (revision 2)
        described_class.new(session_id: 'session-b', commit: false, pull_request: false).run(requirements: 'Add a new feature')
        expect(File.read('new_feature.rb')).to eq("puts 'Feature revision 2'\n")
        expect(File.read('README.md')).to eq("# Doc revision 2\n")
      end
    end
  end
end
