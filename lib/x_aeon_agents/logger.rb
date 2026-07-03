module XAeonAgents
  # Mixin adding logging capabilities
  module Logger
    class << self
      # Global debug switch.
      attr_accessor :debug
    end

    # Log a message if debug was activated
    #
    # @param msg [String, nil] Message to be displayed, or nil if the message is given lazily through a code block
    # @yield [#call -> String] Optional code returning a [String] for lazy evaluation
    # @yieldreturn [String] The message to be displayed
    def log_debug(msg = nil)
      return unless Logger.debug

      msg = yield if block_given?
      puts "[DEBUG] - #{msg}"
    end
  end
end
