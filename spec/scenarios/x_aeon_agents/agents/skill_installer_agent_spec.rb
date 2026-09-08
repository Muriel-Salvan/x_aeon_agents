require_relative 'shared_examples/common_behavior'

describe XAeonAgents::Agents::SkillInstallerAgent do
  it_behaves_like 'an agent with common behavior', described_class

  # Build the output of the `skillkit manifest` command for the given repositories and their skills.
  #
  # @param repos [Hash{String => Array<String>}] Repository names to the skills they provide
  # @return [String] Manifest output, in the same format as the one produced by skillkit
  def manifest_output(repos)
    <<~MANIFEST
      Skills:
      #{repos.map { |repo, skills| "  - #{repo}\n    Skills: #{skills.join(', ')}" }.join("\n")}

      Dependencies:
    MANIFEST
  end

  # Simulate the files created by a skillkit installation of a skill:
  # a .skillkit.json metadata file with the given subpath, and a SKILL.md file
  # declaring the given dependencies (if any) in its front matter.
  #
  # @param skills_dir [String] Directory in which skills are installed
  # @param skill_name [String] Name of the skill
  # @param subpath [String] Value of the subpath property of the skill's .skillkit.json
  # @param dependencies [Array<String>] Dependencies of the skill, as declared in its SKILL.md front matter
  def simulate_installed_skill(skills_dir, skill_name, subpath, dependencies: [])
    skill_dir = File.join(skills_dir, skill_name)
    FileUtils.mkdir_p(skill_dir)
    File.write(File.join(skill_dir, '.skillkit.json'), JSON.dump('subpath' => subpath))
    skill_md = "# #{skill_name}\n"
    unless dependencies.empty?
      front_matter = "metadata:\n  dependencies:\n#{dependencies.map { |dep| "    - #{dep}" }.join("\n")}\n"
      skill_md = "---\n#{front_matter}---\n#{skill_md}"
    end
    File.write(File.join(skill_dir, 'SKILL.md'), skill_md)
  end

  # Stub the skillkit commands:
  # - `skillkit manifest` returns the manifest output for the given repositories, and records
  #   the NO_COLOR environment variable value observed when it is executed.
  # - `skillkit install` records the command being executed and simulates the installation of
  #   the requested skills using their metadata.
  #
  # @param manifest_repos [Hash{String => Array<String>}] Repository names to the skills they provide,
  #   as returned by the mocked `skillkit manifest` command
  # @param skills_metadata [Hash{String => Hash{Symbol => Object}}] Metadata of each skill installed
  #   by the mocked `skillkit install` command:
  #   - subpath [String] Value of the subpath property of the skill's .skillkit.json
  #   - dependencies [Array<String>] Dependencies of the skill, as declared in its SKILL.md front matter
  # @return [Array<Array<String>, Array<String>>] The install commands executed, and the NO_COLOR values
  #   observed when running the skillkit commands
  def stub_skillkit(manifest_repos, skills_metadata)
    install_commands = []
    no_color_values = []
    stub_command(
      /\Askillkit manifest\z/,
      stdout: proc do |_cmd|
        no_color_values << ENV.fetch('NO_COLOR', nil)
        manifest_output(manifest_repos)
      end
    )
    stub_command(
      /\Askillkit install /,
      stdout: proc do |cmd|
        no_color_values << ENV.fetch('NO_COLOR', nil)
        install_commands << cmd
        match_data = cmd.match(/\Askillkit install \S+ --yes --skills=(?<skills>\S+) --agent=\S+\z/)
        match_data[:skills].split(',').each do |skill_name|
          metadata = skills_metadata.fetch(skill_name)
          simulate_installed_skill(
            '.cline/skills', skill_name, metadata.fetch(:subpath), dependencies: metadata.fetch(:dependencies, [])
          )
        end
        ''
      end
    )
    [install_commands, no_color_values]
  end

  context 'when the manifest lists skills to install' do
    it 'installs the skills of each repository and fixes their subpath metadata' do
      with_workspace do
        install_commands, = stub_skillkit(
          { 'repo_one' => %w[skill_a skill_b], 'repo_two' => ['skill_c'] },
          {
            'skill_a' => { subpath: 'sources/skill_a' },
            'skill_b' => { subpath: 'skills/skill_b' },
            'skill_c' => { subpath: 'sources/skill_c' }
          }
        )

        result = described_class.new(session_id: nil).run(agent: 'cline')

        expect(install_commands).to eq [
          'skillkit install repo_one --yes --skills=skill_a,skill_b --agent=cline',
          'skillkit install repo_two --yes --skills=skill_c --agent=cline'
        ]
        expect(result).to eq(installed: true)
        # Skills with a subpath not starting with skills/ have it fixed
        expect(JSON.parse(File.read('.cline/skills/skill_a/.skillkit.json'))['subpath']).to eq 'skills/sources/skill_a'
        expect(JSON.parse(File.read('.cline/skills/skill_c/.skillkit.json'))['subpath']).to eq 'skills/sources/skill_c'
        # Skills with an already correct subpath are left untouched
        expect(File.read('.cline/skills/skill_b/.skillkit.json')).to eq JSON.dump('subpath' => 'skills/skill_b')
      end
    end
  end

  context 'when an installed skill declares dependencies' do
    it 'installs missing dependencies recursively from their repository' do
      with_workspace do
        install_commands, = stub_skillkit(
          { 'repo_one' => ['skill_a'] },
          {
            'skill_a' => { subpath: 'skills/skill_a', dependencies: ['dep_skill', 'repo_two:dep_other'] },
            'dep_skill' => { subpath: 'skills/dep_skill' },
            'dep_other' => { subpath: 'skills/dep_other' }
          }
        )

        described_class.new(session_id: nil).run(agent: :cline)

        # The dependency without repository prefix is installed from the same repository,
        # and the one qualified with a repository prefix is installed from its own repository.
        expect(install_commands).to eq [
          'skillkit install repo_one --yes --skills=skill_a --agent=cline',
          'skillkit install repo_one --yes --skills=dep_skill --agent=cline',
          'skillkit install repo_two --yes --skills=dep_other --agent=cline'
        ]
      end
    end

    it 'does not install dependencies that are already installed' do
      with_workspace do
        FileUtils.mkdir_p('.cline/skills/dep_skill')
        File.write('.cline/skills/dep_skill/SKILL.md', "# dep_skill\n")
        install_commands, = stub_skillkit(
          { 'repo_one' => ['skill_a'] },
          { 'skill_a' => { subpath: 'skills/skill_a', dependencies: ['dep_skill'] } }
        )

        described_class.new(session_id: nil).run(agent: :cline)

        expect(install_commands).to eq ['skillkit install repo_one --yes --skills=skill_a --agent=cline']
      end
    end
  end

  context 'when running the skillkit commands' do
    it 'sets NO_COLOR when running the manifest command and restores its original value afterwards' do
      original_no_color = ENV.fetch('NO_COLOR', nil)
      ENV['NO_COLOR'] = '0'
      with_workspace do
        install_commands, no_color_values = stub_skillkit(
          { 'repo_one' => ['skill_a'] },
          { 'skill_a' => { subpath: 'skills/skill_a' } }
        )

        described_class.new(session_id: nil).run(agent: :cline)

        # NO_COLOR is set to 1 when the manifest command is run, and has been restored
        # to its original value by the time the install commands are run
        expect(no_color_values).to eq %w[1 0]
        expect(install_commands).to eq ['skillkit install repo_one --yes --skills=skill_a --agent=cline']
        expect(ENV.fetch('NO_COLOR', nil)).to eq '0'
      end
    ensure
      ENV['NO_COLOR'] = original_no_color
    end
  end
end
