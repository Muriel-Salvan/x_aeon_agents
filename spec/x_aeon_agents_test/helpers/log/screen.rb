module XAeonAgentsTest
  module Helpers
    module Log
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
        # The raw output is a series of log lines and status redraws, where each new status erases
        # the previous one (through cursor repositioning escape sequences) before redrawing it. A
        # status redraw consists of consecutive status rows (a status emoji or unknown-status dot,
        # optionally ANSI-colored, followed by a space and the step/agent name).
        #
        # @return [String] The last status that has been displayed
        def last_status
          # Collect all the consecutive status rows of the raw output: a status block starts when a
          # line begins with a status emoji and is followed (possibly after a blank separator line)
          # by other status rows or nothing (ie. the block is the final redraw).
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

        # Check if a line starts a status row, ie. it starts with a status emoji or unknown-status
        # dot, optionally preceded by ANSI escape sequences.
        #
        # @param line [String] The line to check
        # @return [Boolean] True if the line starts a status row
        def status_row_line?(line)
          line.match?(/\A\e\[[0-9;]*m/)
        end
      end
    end
  end
end
