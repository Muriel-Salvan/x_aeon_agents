require 'pastel'
require 'stringio'
require 'tty-screen'

module XAeonAgentsTest
  module Helpers
    # Helpers validating the status logging of XAeonAgents::Logger in a TTY context.
    module TtyStatus
      # IO capturing what is written to it while pretending to be a TTY.
      class FakeTtyIO < StringIO
        # Simulate being attached to a TTY.
        #
        # @return [Boolean] Always true
        def tty?
          true
        end
      end

      # Screen capturing what is displayed on the simulated TTY.
      # Its content can be read and cleared at any time, to validate what is being displayed right
      # after any logging event.
      class Screen
        # Constructor
        def initialize
          @io = FakeTtyIO.new
        end

        # @return [StringIO] The IO to plug as $stdout to capture what gets displayed
        attr_reader :io

        # Get the last status that has been displayed.
        # The raw output is a series of log lines and status redraws, where each new status erases the
        # previous one (through cursor repositioning escape sequences) before redrawing it. A status
        # redraw consists of consecutive status rows (a status emoji or unknown-status dot, optionally
        # ANSI-colored, followed by a space and the step/agent name).
        #
        # @return [String] The last status that has been displayed
        def last_status
          # Collect all the consecutive status rows of the raw output: a status block starts when a
          # line begins with a status emoji and is followed (possibly after a blank separator line) by
          # other status rows or nothing (ie. the block is the final redraw).
          status_blocks = []
          previous_was_status = false
          @io.string.split(/\r\n|\n/, -1).each do |line|
            if status_row_line?(line)
              if previous_was_status
                status_blocks.last << line
              else
                status_blocks << [line]
              end
              previous_was_status = true
            else
              previous_was_status = false
              # A status block ends when a log line is met
              status_blocks.pop if status_blocks.any? && line.match(/\S/) && !status_row_line?(line)
            end
          end
          # The last block is the latest redraw: the one that has the most recent status row.
          last_block = status_blocks.reverse.find { |block| block.any? { |l| status_row_line?(l) } }
          last_block ? last_block.join(XAeonAgents::Logger::LINE_SEPARATOR) : ''
        end

        # Check if a line starts a status row, ie. it starts with a status emoji or unknown-status dot,
        # optionally preceded by ANSI escape sequences.
        #
        # @param line [String] The line to check
        # @return [Boolean] True if the line starts a status row
        def status_row_line?(line)
          line.match?(/\A\e\[[0-9;]*m/)
        end
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
        original_stdout = $stdout
        original_logger = XAeonAgents::Config.instance_variable_get(:@logger)
        @tty_screen = screen
        XAeonAgents::Config.instance_variable_set(:@logger, nil)
        $stdout = screen.io
        allow(TTY::Screen).to receive_messages(width: 120, height: 40)
        allow(Pastel).to receive(:new).and_return(forced_colors_pastel)
        begin
          yield
        ensure
          $stdout = original_stdout
          XAeonAgents::Config.instance_variable_set(:@logger, original_logger)
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
