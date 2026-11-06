module XAeonAgentsTest
  module Helpers
    # Helpers to validate the prompts given to agents.
    module Prompts
      # Get the text of all the system instructions of an agent, whatever their format is
      # (a String, a Hash describing instructions, or a list of any of them).
      #
      # @param agent [ComposableAgents::PromptDrivenAgent] The agent whose system instructions are needed
      # @return [String] The text of all the system instructions of the agent
      def system_instructions_text(agent)
        ComposableAgents::Instructions.new(agent.system_instructions).map { |_type, instruction| instruction }.join("\n")
      end
    end
  end
end
