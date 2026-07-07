require 'English'

module XAeonAgentsTest
  module Helpers
    module Cli
      # @return [String, nil] Stdout of the last CLI run, or nil if none
      attr_reader :stdout

      # @return [String, nil] Stderr of the last CLI run, or nil if none
      attr_reader :stderr

      # @return [Integer, nil] Exit status of the last CLI run, or nil if none
      attr_reader :exit_status

      # Run the CLI.
      # Uses default_cli_args to automatically add some CLI args.
      # Result is captured in the following methods: stdout, stderr, exit_status.
      #
      # @param args [Array<String>] CLI arguments
      # @param expect_failure [Boolean] Expect the generate_skills command to fail?
      def run_cli(*args, expect_failure: false)
        unless Debug.debug?
          stdout_io = StringIO.new
          stderr_io = StringIO.new
          $stdout = stdout_io
          $stderr = stderr_io
        end
        begin
          begin
            XAeonAgents::Cli.start(args + (respond_to?(:default_cli_args) ? default_cli_args : []))
            # If we reach here, the command did not call exit (succeeded)
            @exit_status = 0
          rescue SystemExit => e
            @exit_status = e.status
          end
        ensure
          $stdout = STDOUT
          $stderr = STDERR
        end
        unless Debug.debug?
          @stdout = stdout_io.string
          @stderr = stderr_io.string
        end
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
    end
  end
end
