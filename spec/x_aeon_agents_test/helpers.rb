require 'fileutils'
require 'json'
require 'open3'
require 'sqlite3'
require 'time'

module XAeonAgentsTest
  module Helpers
    include Cli
    include Debug
    include GenerateReadme
    include Git
    include Github
    include InterpretDiffs
    include PromptAgentsStub
    include ReviewContent
    include Skills

    # Stub a command that can be run through run_cmd.
    #
    # @param command [String, Regexp] The string to be stubbed, or Regexp for a matching command.
    # @param stdout [String, #call(command) -> String] Command's stdout,
    #   or the code that receives the command that was invoked and should return it.
    # @param stderr [String, #call(command) -> String] Command's stderr,
    #   or the code that receives the command that was invoked and should return it.
    # @param exit_status [Integer, #call(command) -> Integer] Command's exit status,
    #   or the code that receives the command that was invoked and should return it.
    def stub_command(command, stdout: '', stderr: '', exit_status: 0)
      allow(Open3).to receive(:popen3).and_call_original
      allow(Open3).to receive(:popen3).with(command) do |cmd, &block|
        block.call(
          StringIO.new,
          StringIO.new(stdout.is_a?(String) ? stdout : stdout.call(cmd)),
          StringIO.new(stderr.is_a?(String) ? stderr : stderr.call(cmd)),
          instance_double(
            Process::Waiter,
            value: instance_double(
              Process::Status,
              exitstatus: exit_status.is_a?(Integer) ? exit_status : exit_status.call(cmd)
            )
          )
        )
      end
    end

    # Create a temporary directory for the tests
    #
    # @param name [String, nil] Optional name to give to the temporary directory for better debugging, or nil if none.
    # @return [String] The temporary test directory
    def temp_dir(name = nil)
      new_dir = ".x_aeon_agents_test/#{name || Time.now.utc.strftime('%Y-%m-%d-%H-%M-%S-%N')}"
      FileUtils.mkdir_p new_dir
      new_dir
    end

    # Create a temporary workspace directory and cd in it.
    #
    # @yield [#call] Code block to execute within the workspace directory
    def with_workspace(&)
      Dir.chdir(temp_dir('workspace'), &)
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
  end
end
