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
        one_line_message = message.strip.gsub("\n", ' ')
        $stdout.print "#{one_line_message[0..(DEBUG_MESSAGE_MAX_SIZE - 1)]}#{' ' * [0, DEBUG_MESSAGE_MAX_SIZE - one_line_message.size].max}\r"
        $stdout.flush
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

    # Make sure the correct line separator is used depending on the OS.
    # Commands using WSL can mess this up, so we enforce it.
    LINE_SEPARATOR = Gem.win_platform? ? "\r\n" : "\n"

    # Say a message to the user (puts on stdout)
    #
    # @param message [String] Message to say.
    def say(message = '')
      # Pad potential stdout line with spaces to remove potential debug messages that could have been longer than this message.
      $stdout.write "#{message}#{' ' * [0, DEBUG_MESSAGE_MAX_SIZE - message.size].max}#{LINE_SEPARATOR}"
    end
  end
end
