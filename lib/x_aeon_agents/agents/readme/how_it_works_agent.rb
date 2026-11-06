module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "How it works" section of a README.
      class HowItWorksAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            how_it_works: {
              description: 'The "How it works" section content in Markdown format, explaining the internal architecture and working principles of the project',
              type: :markdown
            }
          )
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'How it works section generator',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's architecture, design patterns, and internal workings.
              Generate a "How it works" section in Markdown format, compatible with Github flavor, explaining the internal architecture and working principles.
              Use emphasis, bullet points, useful links to the project resources and small emojis to better format your section.
              You can use SocratiCode if it is available to get a better understanding of this project.
              You can use Mermaid graphs to also illustrate the way this project works.
            EO_OBJECTIVE
            system_instructions: <<~EO_INSTRUCTIONS,
              #{Helpers.repository_access_system_instructions}

              Always gather all the necessary context before starting to work on a task: explore the current repository's code, configuration and documentation to ground your analysis in the actual project.
              If you need more information, use one of the available tools instead of making assumptions.
              Do not indicate that you will perform an action without actually doing it.
            EO_INSTRUCTIONS
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
              - Do not provide long paragraphs: focus on readability by splitting long paragraphs into several short ones.
              - #{Helpers.repository_access_constraint}
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
