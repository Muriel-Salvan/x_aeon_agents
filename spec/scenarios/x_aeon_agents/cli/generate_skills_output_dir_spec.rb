describe XAeonAgents::Cli, '#generate_skills' do
  describe 'output directory' do
    context 'with custom destination directory' do
      it 'generates skills to the specified custom directory' do
        with_skills_src(my_skill: { 'SKILL.md' => '# My Skill' }) do
          run_generate_skills(output_dir: 'my_custom_skills')
          expect(File.directory?('my_custom_skills')).to be true
          expect(File.exist?('my_custom_skills/my_skill/SKILL.md')).to be true
          expect(File.directory?('skills')).to be false
        end
      end
    end

    context 'with nested custom destination directory' do
      it 'creates nested directories as needed' do
        with_skills_src(my_skill: { 'SKILL.md' => '# My Skill' }) do
          run_generate_skills(output_dir: 'output/generated/skills')
          expect(File.directory?('output/generated/skills')).to be true
          expect(File.exist?('output/generated/skills/my_skill/SKILL.md')).to be true
        end
      end
    end
  end
end
