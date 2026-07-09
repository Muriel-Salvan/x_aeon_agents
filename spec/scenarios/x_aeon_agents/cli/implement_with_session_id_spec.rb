describe XAeonAgents::Cli, '#implement' do
  describe 'reusing sessions' do
    before do
      coder_revision = 0
      stub_agent_run(
        stub_handler: lambda { |agent, **kwargs|
          case agent
          when XAeonAgents::Agents::PlanGeneratorAgent
            { plan: "Detailed step-by-step plan for requirements \"#{kwargs[:requirements]}\"" }
          when XAeonAgents::Agents::TesterAgent
            { plan_modifications: '' }
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
      stub_command('bundle exec rspec --format documentation', stdout: "All tests passed\n")
    end

    it 'reuses session to keep old CoderAgent output and uses a new session for fresh output' do
      with_git_workspace(files: { 'test.txt' => "original\n" }) do
        # First run with session A - CoderAgent writes initial content (revision 1)
        run_cli 'implement', 'Add a new feature', '--session-id', 'session-a'
        expect(exit_status).to eq 0
        expect(File.read('new_feature.rb')).to eq("puts 'Feature revision 1'\n")
        expect(File.read('README.md')).to eq("# Doc revision 1\n")

        # Second run with same session A - session is reused, CoderAgent is skipped,
        # so the files still have the old content from the first run
        run_cli 'implement', 'Add a new feature', '--session-id', 'session-a'
        expect(exit_status).to eq 0
        expect(File.read('new_feature.rb')).to eq("puts 'Feature revision 1'\n")
        expect(File.read('README.md')).to eq("# Doc revision 1\n")

        # Third run with different session B - fresh session, CoderAgent produces new content (revision 2)
        run_cli 'implement', 'Add a new feature', '--session-id', 'session-b'
        expect(exit_status).to eq 0
        expect(File.read('new_feature.rb')).to eq("puts 'Feature revision 2'\n")
        expect(File.read('README.md')).to eq("# Doc revision 2\n")
      end
    end
  end
end
