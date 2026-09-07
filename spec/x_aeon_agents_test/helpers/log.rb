require 'pastel'
require 'stringio'
require 'tty-screen'

# Explicitly require the Log sub-constants. This is needed because Zeitwerk does not register
# autoloads for the children of a directory when a file shares its basename (log.rb + log/).
require_relative 'log/fake_tty_io'
require_relative 'log/screen'
require_relative 'log/tee_io'

module XAeonAgentsTest
  module Helpers
    # Helpers managing the logs and statuses of the test suite.
    # All tests run with stdout and stderr globally captured, so that tests not validating logging
    # don't pollute the test runner's output. When TEST_DEBUG is set to 1, the capture is also dumped
    # to the real stdout/stderr in real time, so that what is happening during the tests can be
    # followed.
    module Log
      # @return [Boolean] Are we in test debug mode?
      def self.debug?
        ENV['TEST_DEBUG'] == '1'
      end

      # Log debug a message
      #
      # @param message [String, nil] The message to log debug, or nil if given by a proc returning the message for lazy evaluation
      # @yield The optional code returning the message to log in case of debug
      # @yieldreturn [String] The message to log
      def log_debug(message = nil)
        return unless Log.debug?

        puts "[X-AEON AGENTS TEST DEBUG] - #{block_given? ? yield : message}"
      end

      # Run a block with stdout redirected to a given IO (and stderr when given), with a fresh logger
      # (so that the status and cursor bookkeeping start fresh, and that it writes against the
      # captured IOs). The previous $stdout, $stderr and logger are restored even if the block raises.
      #
      # @param stdout_io [IO] The IO receiving what is written to stdout
      # @param stderr_io [IO, nil] The IO receiving what is written to stderr, or nil to leave $stderr untouched
      # @yield The code to execute with redirected output
      def with_captured_output(stdout_io, stderr_io = nil, &)
        original_stdout = $stdout
        original_stderr = $stderr
        original_logger = XAeonAgents::Config.instance_variable_get(:@logger)
        $stdout = stdout_io
        $stderr = stderr_io if stderr_io
        XAeonAgents::Config.instance_variable_set(:@logger, nil)
        begin
          yield
        ensure
          $stdout = original_stdout
          $stderr = original_stderr if stderr_io
          XAeonAgents::Config.instance_variable_set(:@logger, original_logger)
        end
      end

      # Run a block with everything written to stdout and stderr globally captured.
      # The captured content can be read at any time with #captured_stdout and #captured_stderr,
      # including from within the block.
      # When TEST_DEBUG is set to 1, the capture is also dumped to the real stdout/stderr in real
      # time, through TeeIO instances.
      #
      # @yield The code to execute with captured output
      def with_global_capture(&)
        # Capture the real streams before any redirection, so that TeeIO always forwards to the real
        # stdout/stderr even if this method is called when $stdout/$stderr are already redirected.
        real_stdout = $stdout
        real_stderr = $stderr
        if Log.debug?
          @captured_stdout = TeeIO.new(real_stdout)
          @captured_stderr = TeeIO.new(real_stderr)
        else
          @captured_stdout = StringIO.new
          @captured_stderr = StringIO.new
        end
        with_captured_output(@captured_stdout, @captured_stderr, &)
      end

      # @return [String, nil] The content of what was written to stdout in the global capture of the
      #   current example, or nil if there is no global capture
      def captured_stdout
        @captured_stdout&.string
      end

      # @return [String, nil] The content of what was written to stderr in the global capture of the
      #   current example, or nil if there is no global capture
      def captured_stderr
        @captured_stderr&.string
      end

      # Get the Pastel instance with forced colors, used to build the expected colored statuses.
      #
      # @return [Pastel] The Pastel instance with colors forced
      def status_pastel
        @status_pastel ||= Pastel.new(enabled: true)
      end

      # Log a message through the shared logger, at INFO severity (displayed as a full log line).
      # Useful to snapshot the status being displayed from outside an agent's run.
      #
      # @param message [String] The message to log
      def log_message(message)
        XAeonAgents::Config.logger.info(message)
      end

      # Run a block in a simulated TTY context.
      # Use a fresh logger (so that colors and cursor bookkeeping start fresh), a fixed screen size
      # and forced colors, to make the status display deterministic.
      # The screen capturing what gets displayed is stored in the @tty_screen instance variable, so
      # that it can be polled from anywhere in the example (including from within agents' run stubs),
      # typically right after each logging event, to validate what is being displayed.
      #
      # @yield The code to execute in the simulated TTY context
      def with_tty_status(&)
        # Create the forced-colors Pastel instance before stubbing Pastel.new, as it will be the one
        # returned by the stub to the logger when it creates its own Pastel instance.
        forced_colors_pastel = status_pastel
        screen = Screen.new
        @tty_screen = screen
        allow(TTY::Screen).to receive_messages(width: 120, height: 40)
        allow(Pastel).to receive(:new).and_return(forced_colors_pastel)
        begin
          with_captured_output(screen.io, &)
        ensure
          @tty_screen = nil
        end
      end

      # Validate that the last status displayed on the simulated TTY is the given one.
      # The expectation is exact: the expected status must be the complete last status block, not
      # merely a part of it.
      #
      # @param expected_status [String] The exact expected status
      def expect_last_status_to_be(expected_status)
        expect(@tty_screen.last_status).to eq expected_status
      end

      # Build the exact status string expected to be displayed by the logger for given rows of cells.
      # This mirrors the rendering rules of XAeonAgents::Logger: rows of 4 cells (hierarchical name,
      # cost, progress block, agent's complement name), aligned by TTY::Table with 2-space column
      # separators and no borders, with trailing whitespace stripped on each line.
      #
      # @param rows [Array<Array<String>>] Expected cells, already colorized when applicable
      # @return [String] The expected multi-line status string
      def expected_status_string(rows)
        column_sizes = rows.first.size.times.map do |column_index|
          rows.map { |row| status_visible_size(row[column_index]) }.max
        end
        rows.map do |row|
          row.each_with_index.map do |cell, column_index|
            "#{cell}#{' ' * (column_sizes[column_index] - status_visible_size(cell))}"
          end.join('  ').rstrip
        end.join(XAeonAgents::Logger::LINE_SEPARATOR)
      end

      private

      # Compute the visible size of a string, ignoring ANSI escape sequences (colors...).
      #
      # @param string [String] The string to measure
      # @return [Integer] Number of visible characters
      def status_visible_size(string)
        string.gsub(/\e\[[0-9;]*[A-Za-z]/, '').size
      end
    end
  end
end
