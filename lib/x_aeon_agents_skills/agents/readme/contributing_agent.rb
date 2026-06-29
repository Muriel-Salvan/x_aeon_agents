module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "Contributing" section of a README.
      class ContributingAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(contributing: 'The "Contributing" section content in Markdown format, explaining how to contribute to the project')
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Contributing',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's CONTRIBUTING guidelines, issue templates, pull request templates, and any community guidelines.
              Generate a "Contributing" section in Markdown format, compatible with Github flavor, explaining how users can contribute to the project.
            EO_OBJECTIVE
            **agent_params
          )
        end
      end
    end
  end
end
