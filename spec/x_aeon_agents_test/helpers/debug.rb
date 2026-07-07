module XAeonAgentsTest
  module Helpers
    # Helpers for debug mode
    module Debug
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
        return unless Debug.debug?

        puts "[X-AEON AGENTS TEST DEBUG] - #{block_given? ? yield : message}"
      end
    end
  end
end
