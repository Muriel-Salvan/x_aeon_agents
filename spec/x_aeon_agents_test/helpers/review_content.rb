require 'launchy'

module XAeonAgentsTest
  module Helpers
    # Helpers for stubbing the review_content flow
    module ReviewContent
      # Files that were opened by Launchy during the test
      #
      # @return [Array<Hash{Symbol => Object}>] List of files opened by Launchy. Each description has the following properties:
      #   - path [String] The file path
      #   - content [String] The file content
      def opened_review_files
        @opened_review_files || []
      end

      # Content of the last file opened by Launchy during the test
      #
      # @return [String, nil] Content of the last opened review file, or nil if none
      def reviewed_content
        opened_review_files.last&.[](:content)
      end

      # Stub Launchy.open and $stdin.gets to avoid interactive prompts during tests.
      #
      # @param stdin_response [String] Value to return from $stdin.gets.
      # @yield [file_path] Optional block called when Launchy.open is invoked.
      #   The file has already been written with the content to review.
      #   Use this to modify the file (simulating user editing) before $stdin.gets returns.
      # @yieldparam file_path [String] The path of the file being opened for review
      def stub_review_content(stdin_response: '', &on_file_open)
        @opened_review_files = []
        allow(Launchy).to receive(:open) do |file_path|
          @opened_review_files << { path: file_path, content: File.read(file_path) }
          on_file_open&.call(file_path)
        end
        allow($stdin).to receive(:gets).and_return(stdin_response)
      end
    end
  end
end
