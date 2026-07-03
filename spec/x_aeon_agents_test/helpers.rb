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
      Dir.mktmpdir('test_workspace') do |workspace_dir|
        Dir.chdir(workspace_dir, &block)
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
  end
end
