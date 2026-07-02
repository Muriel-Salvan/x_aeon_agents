module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "Features" section of a README.
      class FeaturesAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash<Symbol, String>] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            features: {
              description: 'The "Features" section content in Markdown format, listing the key features of the project',
              type: :markdown
            }
          )
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Features',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's codebase and capabilities to identify all key features.
              Generate a "Features" section in Markdown format, compatible with Github flavor, listing the main features of the project.
              Use emphasis, bullet points and small emojis to illustrate in a readable way the list of features.
              Don't provide an overall description of the project: another section is already doing it.
            EO_OBJECTIVE
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
