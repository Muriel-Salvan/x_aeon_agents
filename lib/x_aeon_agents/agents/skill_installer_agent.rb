require 'front_matter_parser'

module XAeonAgents
  module Agents
    # Agent responsible for installing skills from the .skills manifest.
    class SkillInstallerAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        { agent: 'Agent name to be used to install skills' }
      end

      # Execute the agent to install skills from the .skills manifest.
      #
      # @param agent [String] Agent name to be used to install skills
      # @return Hash<Symbol,Object> Output artifacts content
      def run(agent: 'cline')
        agent_name = agent.to_sym
        original_no_color = ENV['NO_COLOR']
        ENV['NO_COLOR'] = '1'
        begin
          list_lines = `skillkit manifest`.split("\n")
        ensure
          ENV['NO_COLOR'] = original_no_color
        end
        list_lines = list_lines[list_lines.index('Skills:') + 1..]
        list_lines[0..list_lines.index('') - 1].each_slice(2) do |repo_desc, skills_desc|
          install_skills_recursive(
            repo_desc[4..].strip,
            skills_desc[12..].split(',').map(&:strip),
            agent_name
          )
        end

        puts
        puts 'Skills identified in the skillkit manifest and their dependencies have been installed successfully'
        { installed: true }
      end

      private

      # Install skills using skillkit, including dependencies recursively.
      #
      # @param repo [String] Repository
      # @param skills [Array<String>] Skills to install
      # @param agent [Symbol] Agent to use
      def install_skills_recursive(repo, skills, agent)
        return if skills.empty?

        agents_config = {
          cline: { skills_dir: '.cline/skills' }
        }
        skills_dir = agents_config[agent][:skills_dir]

        puts "Install skills #{repo} / #{skills.join(',')}..."
        system "skillkit install #{repo} --yes --skills=#{skills.join(',')} --agent=#{agent}", exception: true
        fix_skills_metadata(skills, agent)

        # Resolve dependencies
        deps_per_repo = {}
        skills.each do |skill|
          deps = FrontMatterParser::Parser.parse_file("#{skills_dir}/#{skill}/SKILL.md").front_matter.dig('metadata', 'dependencies')
          next if deps.nil?

          deps.each do |skill_dep|
            skill_dep = "#{repo}:#{skill_dep}" unless skill_dep.include?(':')
            skill_dep_repo, skill_dep_name = skill_dep.split(':')
            unless File.exist?("#{skills_dir}/#{skill_dep_name}/SKILL.md")
              deps_per_repo[skill_dep_repo] ||= []
              deps_per_repo[skill_dep_repo] << skill_dep_name unless deps_per_repo[skill_dep_repo].include?(skill_dep_name)
            end
          end
        end

        deps_per_repo.each { |dep_repo, dep_skills| install_skills_recursive(dep_repo, dep_skills, agent) }
      end

      # Fix the .skillkit.json subpath property after skillkit install.
      #
      # @param skills [Array<String>] Installed skills
      # @param agent [Symbol] Agent used
      def fix_skills_metadata(skills, agent)
        require 'json'

        agents_config = { cline: { skills_dir: '.cline/skills' } }
        skills_dir = agents_config[agent][:skills_dir]

        skills.each do |skill_name|
          json_file = "#{skills_dir}/#{skill_name}/.skillkit.json"
          json = JSON.parse(File.read(json_file))
          next if json['subpath'].start_with?('skills/')

          json['subpath'] = "skills/#{json['subpath']}"
          puts "Fix subpath of #{json_file}"
          File.write(json_file, JSON.pretty_generate(json))
        end
      end
    end
  end
end
