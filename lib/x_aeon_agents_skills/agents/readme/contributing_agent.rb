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
          super.merge(
            contributing: {
              description: 'The "Contributing" section content in Markdown format, explaining how to contribute to the project',
              type: :markdown
            }
          )
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
              Focus on giving community specific guidelines (issues, pull requests, CI, fork...).
              Use emphasis, bullet points, useful links to the project resources and small emojis to better format your section.
            EO_OBJECTIVE
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
              - Do not describe the technical setup or prequisites, as they are already covered by other sections.
              - Do not cover how to develop in this project: it is already covered in other sections.
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
