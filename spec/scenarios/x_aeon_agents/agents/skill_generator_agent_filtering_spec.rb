describe XAeonAgents::Agents::SkillGeneratorAgent do
  describe '--skill filter option' do
    context 'with a single skill name' do
      it 'generates only the specified skill' do
        with_skills_src(
          skill_one: { 'SKILL.md' => '# Skill One' },
          skill_two: { 'SKILL.md' => '# Skill Two' },
          skill_three: { 'SKILL.md' => '# Skill Three' }
        ) do
          described_class.new(session_id: nil).run(output_dir: 'skills', skill_names: ['skill_one'])
          expect(File.exist?('skills/skill_one/SKILL.md')).to be true
          expect(File.read('skills/skill_one/SKILL.md')).to eq('# Skill One')
          expect(File.exist?('skills/skill_two')).to be false
          expect(File.exist?('skills/skill_three')).to be false
        end
      end
    end

    context 'with multiple --skill flags' do
      it 'generates only the specified skills' do
        with_skills_src(
          skill_one: { 'SKILL.md' => '# Skill One' },
          skill_two: { 'SKILL.md' => '# Skill Two' },
          skill_three: { 'SKILL.md' => '# Skill Three' }
        ) do
          described_class.new(session_id: nil).run(output_dir: 'skills', skill_names: %w[skill_one skill_three])
          expect(File.exist?('skills/skill_one/SKILL.md')).to be true
          expect(File.exist?('skills/skill_three/SKILL.md')).to be true
          expect(File.exist?('skills/skill_two')).to be false
        end
      end
    end

    context 'with comma-separated skill names' do
      it 'generates only the specified skills from a single --skill value' do
        with_skills_src(
          skill_one: { 'SKILL.md' => '# Skill One' },
          skill_two: { 'SKILL.md' => '# Skill Two' },
          skill_three: { 'SKILL.md' => '# Skill Three' }
        ) do
          described_class.new(session_id: nil).run(output_dir: 'skills', skill_names: ['skill_one,skill_two'])
          expect(File.exist?('skills/skill_one/SKILL.md')).to be true
          expect(File.exist?('skills/skill_two/SKILL.md')).to be true
          expect(File.exist?('skills/skill_three')).to be false
        end
      end
    end

    context 'with mixed --skill flags and comma-separated values' do
      it 'handles a combination of repeated flags and commas' do
        with_skills_src(
          skill_one: { 'SKILL.md' => '# Skill One' },
          skill_two: { 'SKILL.md' => '# Skill Two' },
          skill_three: { 'SKILL.md' => '# Skill Three' }
        ) do
          described_class.new(session_id: nil).run(output_dir: 'skills', skill_names: ['skill_one,skill_two', 'skill_three'])
          expect(File.exist?('skills/skill_one/SKILL.md')).to be true
          expect(File.exist?('skills/skill_two/SKILL.md')).to be true
          expect(File.exist?('skills/skill_three/SKILL.md')).to be true
        end
      end
    end

    context 'with duplicate skill names' do
      it 'deduplicates and generates each skill once' do
        with_skills_src(
          skill_one: { 'SKILL.md' => '# Skill One' },
          skill_two: { 'SKILL.md' => '# Skill Two' }
        ) do
          described_class.new(session_id: nil).run(output_dir: 'skills', skill_names: %w[skill_one skill_one])
          expect(File.exist?('skills/skill_one/SKILL.md')).to be true
          expect(File.exist?('skills/skill_two')).to be false
        end
      end
    end

    context 'with unknown skill names' do
      it 'processes gracefully when non-existent skills are specified' do
        with_skills_src(
          skill_one: { 'SKILL.md' => '# Skill One' }
        ) do
          described_class.new(session_id: nil).run(output_dir: 'skills', skill_names: ['nonexistent'])
          expect(File.exist?('skills/skill_one')).to be false
          expect(File.exist?('skills/nonexistent')).to be false
        end
      end
    end

    context 'with empty --skill option' do
      it 'generates all skills when --skill is omitted' do
        with_skills_src(
          skill_one: { 'SKILL.md' => '# Skill One' },
          skill_two: { 'SKILL.md' => '# Skill Two' }
        ) do
          described_class.new(session_id: nil).run(output_dir: 'skills')
          expect(File.exist?('skills/skill_one/SKILL.md')).to be true
          expect(File.exist?('skills/skill_two/SKILL.md')).to be true
        end
      end
    end
  end
end
