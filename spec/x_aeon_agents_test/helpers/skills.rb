module XAeonAgentsTest
  module Helpers
    module Skills
      # Create a temporary workspace with skills.src directory
      # The skills are defined as a hash: skill_name => { file_path => content }
      # Example: my_skill: { 'SKILL.md' => 'content', 'scripts/test' => 'ls' }
      #
      # @param skills [Hash{String => Hash{String => String}}] Hash of skill names to their file contents
      # @yield [#call] Code block to execute with the workspace directory
      def with_skills_src(**skills)
        with_workspace do
          skills.each do |skill_name, files|
            skill_dir = File.join('skills.src', skill_name.to_s)
            files.each do |file_path, content|
              full_file_path = File.join(skill_dir, file_path)
              FileUtils.mkdir_p(File.dirname(full_file_path))
              File.write(full_file_path, content)
            end
          end
          yield
        end
      end

      # Run the generate_skills CLI command
      #
      # @param output_dir [String, nil] Optional destination directory argument
      # @param skills [Array<String>, nil] Optional array of skill names to pass via --skill
      # @param expect_failure [Boolean] Expect the generate_skills command to fail?
      # @return [String] The output from the generate_skills command
      def run_generate_skills(output_dir: nil, skills: nil, expect_failure: false)
        run_cli(
          *(
            ['generate-skills'] +
            (output_dir ? ['--output-dir', output_dir] : []) +
            (skills || []).map { |skill| ['--skill', skill] }.flatten(1)
          ),
          expect_failure:
        )
      end

      # Helper method that creates a skill with ERB content, runs generate_skills,
      # and returns the generated SKILL.md output
      #
      # @param erb_content [String] The ERB content for SKILL.md.erb
      # @param additional_files [Hash{String => String}] Optional additional files to include in the skill
      # @return [String] The content of the generated SKILL.md file
      def process_erb(erb_content, additional_files = {})
        files = { 'SKILL.md.erb' => erb_content }.merge(additional_files)
        with_skills_src(test_skill: files) do
          run_generate_skills
          File.read('skills/test_skill/SKILL.md')
        end
      end
    end
  end
end
