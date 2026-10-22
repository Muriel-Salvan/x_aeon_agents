require 'front_matter_parser'

module XAeonAgents
  module Agents
    # Agent responsible for installing skills from the .skills manifest.
    class SkillInstallerAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          agent: 'Agent name to be used to install skills',
          global: {
            description: 'Install skills globally instead of in the project',
            optional: true
          }
        }
      end

      # Constructor
      #
      # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
      def initialize(**agent_params)
        super(name: 'Skills installer', **agent_params)
      end

      # Execute the agent to install skills from the .skills manifest.
      #
      # @param agent [String, Symbol] Agent name to be used to install skills
      # @param global [Boolean] Install skills globally (in the user home directory) instead of in the project
      # @return [Hash{Symbol => Object}] Output artifacts content
      def run(agent: 'cline', global: false)
        super
        agent_name = agent.to_sym
        original_no_color = ENV.fetch('NO_COLOR', nil)
        ENV['NO_COLOR'] = '1'
        begin
          list_lines = Helpers.run_cmd('skillkit manifest')[:stdout].split("\n")
        ensure
          ENV['NO_COLOR'] = original_no_color
        end
        list_lines = list_lines[(list_lines.index('Skills:') + 1)..]
        list_lines[0..(list_lines.index('') - 1)].each_slice(2) do |repo_desc, skills_desc|
          install_skills_recursive(
            repo_desc[4..].strip,
            skills_desc[12..].split(',').map(&:strip),
            agent_name,
            global:
          )
        end

        logger << 'Skills identified in the skillkit manifest and their dependencies have been installed successfully'
        { installed: true }
      end

      private

      # Directory in which skills are installed for the given agent.
      #
      # @param _agent [Symbol] Agent to use
      # @param global [Boolean] Whether skills are installed globally
      # @return [String] Skills directory path
      def skills_dir_for(_agent, global)
        # TODO: Adapt to other kinds of agents, or get the directory from skillkit itself.
        if global
          File.join(Dir.home, '.cline', 'skills')
        else
          File.join(Dir.pwd, '.cline', 'skills')
        end
      end

      # Install skills using skillkit, including dependencies recursively.
      #
      # @param repo [String] Repository
      # @param skills [Array<String>] Skills to install
      # @param agent [Symbol] Agent to use
      # @param global [Boolean] Whether skills are installed globally
      def install_skills_recursive(repo, skills, agent, global: false)
        return if skills.empty?

        skills_dir = skills_dir_for(agent, global)

        task(:install_skills, name: 'Install skills', intent: "Install skills #{repo} / #{skills.join(',')}") do
          Helpers.run_cmd("skillkit install #{repo} --yes --skills=#{skills.join(',')} --agent=#{agent}#{' --global' if global}")
          fix_skills_metadata(skills, skills_dir)

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

          deps_per_repo.each { |dep_repo, dep_skills| install_skills_recursive(dep_repo, dep_skills, agent, global:) }
        end
      end

      # Fix the .skillkit.json subpath property after skillkit install.
      #
      # @param skills [Array<String>] Installed skills
      # @param skills_dir [String] Directory in which skills are installed
      def fix_skills_metadata(skills, skills_dir)
        require 'json'

        skills.each do |skill_name|
          json_file = "#{skills_dir}/#{skill_name}/.skillkit.json"
          json = JSON.parse(File.read(json_file))
          next if json['subpath'].start_with?('skills/')

          json['subpath'] = "skills/#{json['subpath']}"
          logger.debug "Fix subpath of #{json_file}"
          File.write(json_file, JSON.pretty_generate(json))
        end
      end
    end
  end
end
