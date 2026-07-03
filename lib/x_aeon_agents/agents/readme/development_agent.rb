module XAeonAgents
  module Agents
    module Readme
      # Agent responsible for generating the "Development" section of a README.
      class DevelopmentAgent < ComposableAgents::Cline::Agent
        prepend AgentDefaults

        # Define output artifacts contracts
        #
        # @return [Hash{Symbol => Object}] Set of output artifacts description, per artifact name
        def output_artifacts_contracts
          super.merge(
            development: {
              description: 'The "Development" section content in Markdown format, explaining how to set up a development environment and contribute code',
              type: :markdown
            }
          )
        end

        # Constructor
        #
        # @param agent_params [Hash{Symbol => Object}] Extra agent parameters
        def initialize(**agent_params)
          super(
            name: 'Development',
            objective: <<~EO_OBJECTIVE,
              Analyze the project's development setup, build system, testing framework, and development workflows.
              Generate a "Development" section in Markdown format, compatible with Github flavor, explaining how to set up a development environment and how to code in it.
              This section is intended for developers.
              Explain how to:
              - clone the repository,
              - install test-specific dependencies if any,
              - run tests,
              - use code lint if any,
              - navigate the project structure (high-level, no need for details),
              - package the project deliverables,
              - perform common development tasks.
            EO_OBJECTIVE
            constraints: <<~EO_CONSTRAINTS,
              - The required output artifact content should only contain the required content, without additional header or title.
              - Do not explain or describe the artifact content: only provide the content as required.
              - Only focus on the specific scope of the required documentation required.
                Other agents will generate other sections of the README.
                Do not try to document other parts.
              - Do not cover the end-user main requirements and prerequisites: they are already covered in other sections.
              - Do not cover the contribution workflow (pull requests, CI, issues...): this is already covered in other sections.
            EO_CONSTRAINTS
            **agent_params
          )
        end
      end
    end
  end
end
