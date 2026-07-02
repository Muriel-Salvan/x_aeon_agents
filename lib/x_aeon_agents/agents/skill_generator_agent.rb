module XAeonAgents
  module Agents
    # Agent responsible for generating skill files from ERB templates.
    class SkillGeneratorAgent < ComposableAgents::Agent
      prepend AgentDefaults

      # Define input artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of input artifacts description, per artifact name
      def input_artifacts_contracts
        { output_dir: 'Output directory for generated skills' }
      end

      # Define output artifacts contracts
      #
      # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
      def output_artifacts_contracts
        { success: 'Whether the skill generation was successful' }
      end

      # Execute the agent to generate skill files from ERB templates.
      #
      # @param output_dir [String] Output directory for generated skills
      # @return Hash<Symbol,Object> Output artifacts content
      def run(output_dir: 'skills')
        transformations = {
          '.erb' => proc { |src_file| XAeonAgents::GenHelpers::ErbEvaluator.new(src_file).result }
        }.freeze

        src_dir = File.expand_path('skills.src')
        src_pathname = Pathname.new(src_dir)
        dest_dir = File.expand_path(output_dir)

        FileUtils.mkdir_p(dest_dir)

        failed = false
        Dir.glob(File.join(src_dir, '**', '*'), File::FNM_DOTMATCH).
          select { |f| File.file?(f) && File.basename(f) != '.skill_config.yml' }.
          each do |src_file|
            relative_path = Pathname.new(src_file).relative_path_from(src_pathname).to_s
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
