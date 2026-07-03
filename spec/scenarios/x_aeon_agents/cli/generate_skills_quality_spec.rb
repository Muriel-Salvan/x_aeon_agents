require 'fileutils'

describe XAeonAgents::Cli, '#generate_skills' do
  describe 'generated skills\' quality' do
    compliance_score_threshold = 90
    quality_score_thresholds = {
      Structure: 90,
      Clarity: 90,
      Specificity: 90,
      Advanced: 90,
      'Average score': 90
    }
    skills_test_dir = 'skills.test'

    before(:context) do
      # Generate skills for tests
      FileUtils.rm_rf skills_test_dir
      run_generate_skills(output_dir: skills_test_dir)
    end

    Dir.glob('skills.src/*').map { |skill_path| File.basename(skill_path) }.each do |skill_name|
      skill_path = "#{skills_test_dir}/#{skill_name}"

      context "validating skill #{skill_name}" do
        it "has a compliance score of at least #{compliance_score_threshold}%" do
          check_output = without_cli_colors { `skillkit skillmd check #{skill_path} --verbose` }
          score = Integer(check_output.match(%r{Score: (\d+)/100$})[1])
          expect(score).to be >= compliance_score_threshold, "Compliance score of #{skill_path} is too low (#{score}/100):\n#{check_output}"
        end

        it 'has good quality scores' do
          skipped_quality_checks = ((XAeonAgents::GenHelpers.config(File.basename(skill_path)) || {})['skip_quality_checks'] || '').split(',').map(&:strip)
          check_output = without_cli_colors { `skillkit validate #{skill_path} --verbose` }
          quality_score_thresholds.each do |quality_property, quality_threshold|
            next if skipped_quality_checks.include?(quality_property.to_s)

            score = Integer(check_output.match(%r{#{Regexp.escape(quality_property)}: (\d+)/100$})[1])
            expect(score).to be >= quality_threshold, "Quality score (#{quality_property}) of #{skill_path} is too low (#{score}/100):\n#{check_output}"
          end
        end
      end
    end
  end
end
