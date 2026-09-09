module XAeonAgentsTest
  module Helpers
    module Log
      # IO capturing what is written to it while pretending to be a TTY.
      class FakeTtyIO < StringIO
        # Simulate being attached to a TTY.
        #
        # @return [Boolean] Always true
        def tty?
          true
        end
      end
    end
  end
end
