require 'fileutils'

describe 'skills' do
  describe 'generated skills\' quality' do
    Dir.glob('skills.src/*').map { |skill_path| File.basename(skill_path) }.each do |skill_name|
      context "with skill #{skill_name}" do
        # @return [String] This specific skill's path
        let(:skill_path) { "#{XAeonAgentsTest::Skills.skills_test_dir}/#{skill_name}" }

        before do
          # Generate skills for tests
          FileUtils.rm_rf XAeonAgentsTest::Skills.skills_test_dir
          run_generate_skills(output_dir: XAeonAgentsTest::Skills.skills_test_dir, skills: [skill_name])
        end

        it "has a compliance score of at least #{XAeonAgentsTest::Skills.compliance_score_threshold}%" do
          check_output = without_cli_colors { `skillkit skillmd check #{skill_path} --verbose` }
          score = Integer(check_output.match(%r{Score: (\d+)/100$})[1])
          expect(score).to(
            be >= XAeonAgentsTest::Skills.compliance_score_threshold,
            "Compliance score of #{skill_path} is too low (#{score}/100):\n#{check_output}"
          )
        end

        it 'has good quality scores' do
          skipped_quality_checks = ((XAeonAgents::GenHelpers.config(File.basename(skill_path)) || {})['skip_quality_checks'] || '').split(',').map(&:strip)
          check_output = without_cli_colors { `skillkit validate #{skill_path} --verbose` }
          XAeonAgentsTest::Skills.quality_score_thresholds.each do |quality_property, quality_threshold|
            next if skipped_quality_checks.include?(quality_property.to_s)

            score = Integer(check_output.match(%r{#{Regexp.escape(quality_property)}: (\d+)/100$})[1])
            expect(score).to be >= quality_threshold, "Quality score (#{quality_property}) of #{skill_path} is too low (#{score}/100):\n#{check_output}"
          end
        end
      end
    end
  end
end
