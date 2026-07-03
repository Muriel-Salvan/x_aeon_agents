require 'sqlite3'
require 'json'
require 'fileutils'
require 'tmpdir'

module XAeonAgentsTest
  module Helpers
    # Create a temporary workspace directory
    # Sets @workspace_dir to the created directory path
    #
    # @yield [#call] Code block to execute with the workspace directory
    def with_workspace
      Dir.mktmpdir('test_skills_workspace') do |workspace_dir|
        @workspace_dir = workspace_dir
        yield @workspace_dir
      end
    end

    # Create a temporary workspace with skills.src directory
    # The skills are defined as a hash: skill_name => { file_path => content }
    # Example: my_skill: { 'SKILL.md' => 'content', 'scripts/test' => 'ls' }
    #
    # @param skills [Hash{String => Hash{String => String}}] Hash of skill names to their file contents
    # @yield [#call] Code block to execute with the workspace directory
    def with_skills_src(**skills)
      with_workspace do |workspace_dir|
        skills_src_dir = File.join(workspace_dir, 'skills.src')
        skills.each do |skill_name, files|
          skill_dir = File.join(skills_src_dir, skill_name.to_s)
          files.each do |file_path, content|
            full_file_path = File.join(skill_dir, file_path)
            FileUtils.mkdir_p(File.dirname(full_file_path))
            File.write(full_file_path, content)
          end
        end
        yield workspace_dir
      end
    end

    # Run the generate_skills Thor command from the workspace directory
    # Assumes @workspace_dir is set by with_skills_src
    #
    # @param dest_dir [String, nil] Optional destination directory argument
    # @param expect_failure [Boolean] Expect the generate_skills command to fail?
    # @return [String] The output from the generate_skills command
    def run_generate_skills(dest_dir = nil, expect_failure: false)
      full_script_path = File.expand_path('./bin/xaa')
      output = nil
      Dir.chdir(@workspace_dir) do
        output = `ruby "#{full_script_path}" generate-skills#{dest_dir ? " --output-dir #{dest_dir}" : ''} 2>&1`
        raise "Command failed: #{output}" if !$?.success? && !expect_failure
      end
      output
    end

    # Helper method to temporarily set an environment variable
    # Uses begin...ensure to guarantee the original value is restored
    #
    # @param var_name [String] Name of the environment variable
    # @param value [String] Temporary value to set
    # @yield [#call] Code block to execute with the temporary value
    def with_env_var(var_name, value)
      original_value = ENV[var_name]
      ENV[var_name] = value
      begin
        yield
      ensure
        ENV[var_name] = original_value
      end
    end

    # Helper method to temporarily disable CLI colors
    # Sets NO_COLOR=1 to disable colored output in CLI commands
    # Uses begin...ensure to guarantee the original value is restored
    #
    # @yield [#call] Code block to execute without CLI colors
    def without_cli_colors
      original_no_color = ENV['NO_COLOR']
      ENV['NO_COLOR'] = '1'
      begin
        yield
      ensure
        ENV['NO_COLOR'] = original_no_color
      end
    end

    # Helper method to setup a VSCode SQLite database with test data
    # Creates the database file, table structure, and inserts items
    #
    # @param vscode_portable_dir [String] Base directory for the VSCode portable setup
    # @param items [Array<Hash{Symbol => String}>] Array of items to insert into the ItemTable.
    #   Each item should be a hash with :key and :value keys.
    #   Can be empty to test "key not found" scenarios.
    # @yield [#call] Code block to execute with the database setup
    def with_vscode_db(vscode_portable_dir, items)
      # Create the required directory structure
      db_dir = File.join(vscode_portable_dir, 'user-data', 'User', 'globalStorage')
      FileUtils.mkdir_p(db_dir)

      # Create the SQLite database
      db_path = File.join(db_dir, 'state.vscdb')
      db = SQLite3::Database.new(db_path)
      db.execute('CREATE TABLE ItemTable (key TEXT PRIMARY KEY, value TEXT)')

      # Insert items into the database
      items.each do |item|
        db.execute(
          'INSERT INTO ItemTable (key, value) VALUES (?, ?)',
          [item[:key], JSON.dump(item[:value])]
        )
      end

      db.close

      yield
    end

    # Helper method that creates a skill with ERB content, runs generate_skills,
    # and returns the generated SKILL.md output
    #
    # @param erb_content [String] The ERB content for SKILL.md.erb
    # @param additional_files [Hash{String => String}] Optional additional files to include in the skill
    # @return [String] The content of the generated SKILL.md file
    def process_erb(erb_content, additional_files = {})
      files = { 'SKILL.md.erb' => erb_content }.merge(additional_files)
      with_skills_src(test_skill: files) do |workspace_dir|
        run_generate_skills
        File.read("#{workspace_dir}/skills/test_skill/SKILL.md")
      end
    end
  end
end
