module XAeonAgentsTest
  module Skills
    class << self
      # @return [String] Local skills' test directory
      def skills_test_dir
        'skills.test'
      end

      # @return [Integer] The skills' quality  compliance threshold
      def compliance_score_threshold
        90
      end

      # @return [Hash{Symbol => Integer}] The various quality score thresholds we evaluate
      def quality_score_thresholds
        {
          Structure: 90,
          Clarity: 90,
          Specificity: 90,
          Advanced: 90,
          'Average score': 90
        }
      end
    end
  end
end
