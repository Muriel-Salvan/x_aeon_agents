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
            name: 'Development section generator',
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
            system_instructions: <<~EO_INSTRUCTIONS,
              #{Helpers.repository_access_system_instructions}

              Always gather all the necessary context before starting to work on a task: explore the current repository's code, configuration and documentation to ground your analysis in the actual project.
              If you need more information, use one of the available tools instead of making assumptions.
              Do not indicate that you will perform an action without actually doing it.
            EO_INSTRUCTIONS
            **agent_params
          )
          self.constraints = <<~EO_CONSTRAINTS
            - Write only the required content to the output artifact file, without any additional header or title.
            - Do NOT write any explanation or description in the artifact file: write only the required content.
            - Only focus on the specific scope of the required documentation required.
              Other agents will generate other sections of the README.
              Do not try to document other parts.
            - Do not cover the end-user main requirements and prerequisites: they are already covered in other sections.
            - Do not cover the contribution workflow (pull requests, CI, issues...): this is already covered in other sections.
            - #{Helpers.repository_access_constraint}
            - #{Helpers.artifacts_access_constraint(artifact_ref(:development))}
          EO_CONSTRAINTS
        end
      end
    end
  end
end
