module XAeonAgentsTest
  module Helpers
    module Log
      # IO writing to a real IO what is written to it, while also buffering it (turning it into a
      # StringIO-compatible capture).
      # Used in debug mode so that logs and statuses are both captured and dumped to the real
      # stdout/stderr in real time.
      class TeeIO < StringIO
        # Constructor
        #
        # @param real_io [IO] The IO to mirror writes to
        def initialize(real_io)
          super()
          @real_io = real_io
        end

        # Write a string to both the real IO and the buffer.
        # #puts, #print and #<< all dispatch to #write, so overriding it alone is enough.
        #
        # @param string [String] The string to write
        # @return [Integer] The number of bytes written
        def write(string)
          @real_io.write string
          super
        end

        # Flush both the real IO and the buffer.
        #
        # @return [self]
        def flush
          @real_io.flush
          super
        end

        # Simulate the TTY-ness of the real IO, so that the status-aware output machinery of the
        # logger behaves the same as it would against the real IO.
        #
        # @return [Boolean] Is the real IO a TTY?
        def tty?
          @real_io.tty?
        end
      end
    end
  end
end
