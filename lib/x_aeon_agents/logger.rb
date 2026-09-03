require 'time'

module XAeonAgents
  # Mixin adding logging capabilities
  module Logger
    class << self
      # Global debug switch.
      attr_accessor :debug
    end

    # Maximum size of debug messages printed for progress, in characters
    DEBUG_MESSAGE_MAX_SIZE = 80

    # Log a message
    #
    # @param message [String, nil] Message to be displayed, or nil if the message is given lazily through a code block
    # @param level [Symbol] Message level
    # @yield [#call -> String] Optional code returning a [String] for lazy evaluation
    # @yieldreturn [String] The message to be displayed
    def log(message, level: :info)
      message = yield if block_given?
      log_line = "[#{Time.now.utc.strftime('%F %T')}] - [#{level.to_s[0].upcase}] - #{message}"
      if level != :debug || Logger.debug
        say log_line
      else
        # Put debug logs just as the last line, just to show activity without putting too much on screen.
        log_output(message.strip.gsub("\n", ' ')[0..(DEBUG_MESSAGE_MAX_SIZE - 1)], new_line: false)
      end
    end

    # Log a debug message
    #
    # @param message [String] Message to log.
    def log_debug(message)
      log(message, level: :debug)
    end

    # Log a warn message
    #
    # @param message [String] Message to log.
    def log_warn(message)
      log(message, level: :warn)
    end

    # Say a message to the user (puts on stdout)
    #
    # @param message [String] Message to say.
    def say(message = '')
      log_output(message)
    end

    private

    # Make sure the correct line separator is used depending on the OS.
    # Commands using WSL can mess this up, so we enforce it.
    LINE_SEPARATOR = Gem.win_platform? ? "\r\n" : "\n"

    # Output a given line to stdout.
    # Handle the case when we are in TTY or not.
    # - If in a TTY: Output the line with padding and display a status if any at the bottom.
    # - Else: Output the line, unless it shouldn't have a new line at the end (meaning it was a debug line not supposed to stay on screen).
    #
    # @param message [String] The message to output
    # @param new_line [Boolean] Should we insert a new line or get back at the line start after this message?
    def log_output(message, new_line: true)
      if $stdout.tty?
        # TODO: Integrate this with the status display properly.
        # Pad potential stdout line with spaces to remove potential debug messages that could have been longer than this message.
        $stdout.write "#{message}#{' ' * [0, DEBUG_MESSAGE_MAX_SIZE - message.size].max}#{new_line ? LINE_SEPARATOR : "\r"}"
        $stdout.flush
      elsif new_line
        $stdout.write "#{message}#{LINE_SEPARATOR}"
        $stdout.flush
      end
    end
  end
end
