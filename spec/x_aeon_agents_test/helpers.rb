require 'English'
require 'sqlite3'
require 'json'
require 'fileutils'
require 'tmpdir'

module XAeonAgentsTest
  module Helpers
    # Create a temporary workspace directory and cd in it.
    #
    # @yield [#call] Code block to execute within the workspace directory
    def with_workspace(&block)
      Dir.mktmpdir('test_skills_workspace') do |workspace_dir|
        Dir.chdir(workspace_dir, &block)
      end
    end

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
    # @param expect_failure [Boolean] Expect the generate_skills command to fail?
    # @return [String] The output from the generate_skills command
    def run_generate_skills(output_dir: nil, expect_failure: false)
      run_cli(
        *(['generate-skills'] + (output_dir ? ['--output-dir', output_dir] : [])),
        expect_failure:
      )
    end

    # @return [String, nil] Stdout of the last CLI run, or nil if none
    attr_reader :stdout

    # @return [String, nil] Stderr of the last CLI run, or nil if none
    attr_reader :stderr

    # @return [Integer, nil] Exit status of the last CLI run, or nil if none
    attr_reader :exit_status

    # Run the CLI.
    # Result is captured in the following methods: stdout, stderr, exit_status.
    #
    # @param args [Array<String>] CLI arguments
    # @param expect_failure [Boolean] Expect the generate_skills command to fail?
    def run_cli(*args, expect_failure: false)
      stdout_io = StringIO.new
      stderr_io = StringIO.new
      $stdout = stdout_io
      $stderr = stderr_io
      begin
        begin
          XAeonAgents::Cli.start(args)
          # If we reach here, the command did not call exit (succeeded)
          @exit_status = 0
        rescue SystemExit => e
          @exit_status = e.status
        end
      ensure
        $stdout = STDOUT
        $stderr = STDERR
      end
      @stdout = stdout_io.string
      @stderr = stderr_io.string
      if expect_failure
        expect(exit_status).not_to eq 0
      else
        expect(exit_status).to eq 0
      end
    end

    # Helper method to temporarily set an environment variable
    # Uses begin...ensure to guarantee the original value is restored
    #
    # @param var_name [String] Name of the environment variable
    # @param value [String] Temporary value to set
    # @yield [#call] Code block to execute with the temporary value
    def with_env_var(var_name, value)
      original_value = ENV.fetch(var_name, nil)
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
      original_no_color = ENV.fetch('NO_COLOR', nil)
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
      with_skills_src(test_skill: files) do
        run_generate_skills
        File.read('skills/test_skill/SKILL.md')
      end
    end
  end
end
