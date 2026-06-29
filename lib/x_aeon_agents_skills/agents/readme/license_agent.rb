module XAeonAgentsSkills
  module Agents
    module Readme
      # Agent responsible for generating the "License" section of a README.
      class LicenseAgent < ComposableAgents::Cline::Agent
        prepend XAeonAgentsSkills::AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(license: 'The "License" section content in Markdown format, describing the project license information')
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'License',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's LICENSE file to identify the license type and terms.
              Generate a "License" section in Markdown format, compatible with Github flavor, describing the project license.
            EO_OBJECTIVE
            **agent_params
          )
        end
      end
    end
  end
end
