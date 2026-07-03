require 'fileutils'
require 'pathname'

module XAeonAgents
  module Agents
    # Agent responsible for generating skill files from ERB templates.
    class SkillGeneratorAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        {
          output_dir: 'Output directory for generated skills',
          skill_names: {
            description: 'Optional list of skill names to generate. If nil or empty, all skills are generated.',
            optional: true
          }
        }
      end

      # Define output artifacts contracts
      #
      # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        { success: 'Whether the skill generation was successful' }
      end

      # Execute the agent to generate skill files from ERB templates.
      #
      # @param output_dir [String] Output directory for generated skills
      # @param skill_names [Array<String>, nil] Optional list of skill names to generate.
      #   Supports comma-separated values within each element. If nil or empty, all skills are generated.
      # @return [Hash{Symbol => Object}] Output artifacts content
      def run(output_dir: 'skills', skill_names: nil)
        transformations = {
          '.erb' => proc { |src_file| GenHelpers::ErbEvaluator.new(src_file).result }
        }.freeze

        src_dir = File.expand_path('skills.src')
        src_pathname = Pathname.new(src_dir)
        dest_dir = File.expand_path(output_dir)

        FileUtils.mkdir_p(dest_dir)

        # Normalize skill_names: flatten, split by comma, strip, compact, uniq
        normalized_skill_names = (skill_names || [])
          .flat_map { |name| name.split(',') }
          .map(&:strip)
          .reject(&:empty?)
          .uniq

        failed = false
        Dir.glob(File.join(src_dir, '**', '*'), File::FNM_DOTMATCH)
          .select { |f| File.file?(f) && File.basename(f) != '.skill_config.yml' }
          .each do |src_file|
            relative_path = Pathname.new(src_file).relative_path_from(src_pathname).to_s
            # Determine the top-level skill directory for this file.
            # Skip files whose top-level skill directory is not in the requested list
            next if !normalized_skill_names.empty? && !normalized_skill_names.include?(relative_path.split('/').first)

            file_ext = File.extname(relative_path)
            dst_file = File.join(
              dest_dir,
              transformations.key?(file_ext) ? relative_path.sub(/#{Regexp.escape(file_ext)}$/, '') : relative_path
            )
            puts "Processing: #{relative_path}"
            puts "    Output: #{dst_file}"
            begin
              FileUtils.mkdir_p(File.dirname(dst_file))
              if transformations.key?(file_ext)
                File.write(dst_file, transformations[file_ext].call(src_file))
              else
                FileUtils.cp(src_file, dst_file)
              end
              puts '    Status: ✓ Processed successfully'
            rescue StandardError => e
              puts "    Status: ✗ Error - #{e.message}\n    #{e.backtrace.first}"
              failed = true
            end
            puts
          end

        puts
        if failed
          puts 'Skills generated with some errors (see above).'
        else
          puts 'Skills generated successfully.'
        end
        { success: !failed }
      end
    end
  end
end
