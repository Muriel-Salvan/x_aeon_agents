require 'agents'
require 'commonmarker'
require 'composable_agents'
require 'front_matter_parser'
require 'git'
require 'json'
require 'launchy'
require 'octokit'
require 'ruby_llm/model/info'
require 'time'

module XAeonAgentsSkills

  module Agents

    class << self

      include Logger

      # Execute a simple task
      #
      # Parameters::
      # * *prompt* (String): The prompt for this task
      def execute_simple_task(prompt)
        agent = ExecutorAgent.new(**Models.free_simple)
        agent.run(user_message: prompt)
        puts agent.conversation.last[:message]
      end

      # Commit current code diffs.
      # If the staging area is empty, add everything.
      # Ask for a confirmation on the message from an editor.
      def commit
        CommitterAgent.new.run
      end

      # Interpret current code diffs
      #
      # Parameters::
      # * *git_ref_base* (Object): Git base (sha, objectish...) with which we diff [default = 'HEAD']
      # Result::
      # * String: Code diffs interpretation
      def interpret_diffs(git_ref_base = 'HEAD')
        git_diff_interpreter_agent_output = GitDiffInterpreterAgent.new.run(git_ref_base:)
        puts <<~EO_OUTPUT
          ===== Code diffs interpretation:

          #{git_diff_interpreter_agent_output[:one_line_summary].strip}

          #{git_diff_interpreter_agent_output[:change_intent].strip}
        EO_OUTPUT
      end

      # Implement a Github issue
      #
      # Parameters::
      # * *github_issue_number* (Integer): The Github issue number to implement
      # * *run_id* (String or nil): The associated run ID, or nil if no persistence needed [default: nil]
      def implement_github_issue(github_issue_number, run_id: nil)
        issue = Helpers.github.issue(Helpers.github_repo, github_issue_number)
        issue_comments = Helpers.github.issue_comments(Helpers.github_repo, github_issue_number)
        sections = [
          <<~EO_Section
            # #{issue.title}
            
            #{ComposableAgents::Utils::Markdown.align_markdown_headers(issue.body, level: 2)}
          EO_Section
        ]
        sections << <<~EO_Section unless issue_comments.empty?
          # Comments
            
          This is the conversation log that happened in this issue.
          This is provided as a reference to better understand the requirements.

          #{format_comments_for_artifact(issue_comments)}
        EO_Section
        sections << <<~EO_Section
          # Associated Github issue
          
          - Number: #{issue.number}
          - Labels: #{issue.labels.map(&:name).join(', ')}
          - State: #{issue.state}
          - URL: #{issue.html_url}
        EO_Section
        implement_requirements(sections.map(&:strip).join("\n\n"), run_id:, commit: true, pull_request: true)
      end

      # Implement some requirements, given a classic dev cycle:
      # 1. Planning
      # 2. Development
      # 3. Testing
      # 4. Documentation
      # 5. Releasing
      #
      # Parameters::
      # * *requirements* (String): Requirements to be implemented
      # * *run_id* (String or nil): The associated run ID, or nil if no persistence needed [default: nil]
      # * *commit* (Boolean): Do we commit changes? [default: false]
      # * *pull_request* (Boolean): Do we create a Pull Request (if not done already) for these requirements? [default: false]
      def implement_requirements(requirements, run_id: nil, commit: false, pull_request: false)
        DeveloperAgent.new(commit:, pull_request:, run_id:).run(requirements:)
      end

      # Address Pull Request comments by finding open PRs, extracting agent-directed comments,
      # implementing requirements, and replying to comments.
      #
      # Parameters::
      # * *pull_request_number* (Integer): The Pull Request number to address comments for
      # * *run_id* (String or nil): The associated run ID, or nil if no persistence needed [default: nil]
      def address_pull_request_comments(pull_request_number, run_id: nil)
        ReviewResolverAgent.new(run_id:).run(pull_request_number:)
      end

      private

      # Format comments for use in artifacts
      #
      # Parameters::
      # * *comments* (Array<Octokit::IssueComment>): Comments to format
      # Result::
      # * String: Formatted comments as markdown
      def format_comments_for_artifact(comments)
        return "No comments" if comments.empty?
        
        comments.sort_by(&:created_at).map do |comment|
          <<~EO_Comment
            ## #{comment.user.login} at #{comment.created_at.utc.strftime('%F %T UTC')}
            
            #{ComposableAgents::Utils::Markdown.align_markdown_headers(comment.body, level: 3)}
          EO_Comment
        end.join("\n")
      end

      # Get the read-only configuration used by agents that are planning and analyzing code
      #
      # Result::
      # * Hash: The read-only configuration
      def read_only_config
        @read_only_config ||= Helpers.deep_merge(
          Configuration.config[:default_cline_config],
          {
            autoApprovalSettings: {
              actions: {
                readFiles: true,
                readFilesExternally: true,
                editFiles: false,
                editFilesExternally: false,
                executeSafeCommands: true,
                executeAllCommands: false,
                useBrowser: true,
                useMcp: true
              }
            },
            strictPlanModeEnabled: true
          }
        )
      end

      # Create the PRRequirementsExtractor agent
      #
      # Result::
      # * ::Agents::Agent: The PRRequirementsExtractor agent
      def pr_requirements_extractor_agent
        @pr_requirements_extractor_agent ||= cline_agent(
          name: 'PRRequirementsExtractor',
          objective: 'Extract requirements from PR comments directed at X-Aeon Agents',
          input_artifacts: [
            { name: :pr_description, description: 'Pull Request description (context)' },
            { name: :pr_files_diffs, description: 'Files modifications that were done in this Pull Request (context)' },
            { name: :conversations, description: 'All Pull Request conversations and comments to be considered (context)' },
            { name: :open_comments_to_agents, description: 'Exact list of agent-directed comments that need to be addressed' }
          ],
          output_artifacts: [
            { name: :requirements, description: 'the requirements that will implement what is needed by the agent-directed comments (reply "No requirements" if there is no implementation needed)' }
          ],
          config: read_only_config,
          instructions: <<~EO_Instructions,
            ## 1. Read the `ARTIFACT_PR_DESCRIPTION` artifact to understand the purpose of this Pull Request
            
            - This gives you context on what is the purpose of this Pull Request.

            ## 2. Read the `ARTIFACT_PR_FILES_DIFFS` artifact to understand all changes made by this Pull Request
            
            - This gives you context on how has this Pull Request been implemented.

            ## 3. Read the `ARTIFACT_CONVERSATIONS` artifact to understand the full context of the PR conversations
            
            - This gives you context on the discussions around this Pull Request.

            ## 4. Read the `ARTIFACT_OPEN_COMMENTS_TO_AGENTS` artifact to focus on agent-directed comments
            
            - You must devise requirements that will address those exact comments.

            ## 5. Analyze agent-directed comments to identify specific requirements or tasks that need implementation
            
            ## 6. Extract clear, actionable requirements from the comments
            
            - If no implementation is required (e.g., comments are just questions), output "No requirements"
          EO_Instructions
          constraints: <<~EO_Constraints
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - Focus only on agent-directed comments (/agent) for requirement extraction.
            - Output clear, actionable requirements or "No requirements" if none exist.
          EO_Constraints
        )
      end

      # Create the ReviewResponder agent
      #
      # Result::
      # * ::Agents::Agent: The ReviewResponder agent
      def review_responder_agent
        @review_responder_agent ||= cline_agent(
          name: 'ReviewResponder',
          objective: 'Generate a reply to a review comment',
          input_artifacts: [
            { name: :conversations, description: 'All PR conversations and comments to be considered (context)' },
            { name: :open_comment_for_reply, description: 'Exact comment to be replied to' },
            { name: :requirements, description: 'Requirements implemented (or "No requirements")' },
            { name: :plan, description: 'Implementation plan from implement_requirements workflow (or "No implementation plan")' },
            { name: :files_diffs, description: 'Code changes from implement_requirements workflow (or "No changes")' }
          ],
          output_artifacts: [
            { name: :reply, description: 'the exact reply text to post' }
          ],
          plan_mode: false,
          config: read_only_config.merge(
            doubleCheckCompletionEnabled: false
          ),
          instructions: <<~EO_Instructions,
            ## 1. Read the `ARTIFACT_CONVERSATIONS` artifact to understand the full context of the PR conversations
            
            - This gives you context on the discussions around this Pull Request.
            
            ## 2. Read the `ARTIFACT_REQUIREMENTS` artifact to understand what was implemented
            
            - This gives you context on what has been implemented by other agents.
            
            ## 3. Read the `ARTIFACT_PLAN` artifact to understand the implementation approach
            
            - This gives you context on how other agents implemented the requirements.

            ## 4. Read the `ARTIFACT_FILES_DIFFS` artifact to understand the specific code changes made

            - This gives you context on what files have been modified.

            ## 5. Read the `ARTIFACT_OPEN_COMMENT_FOR_REPLY` artifact to understand the specific comment to respond to
            
            - This is the EXACT comment that you should reply to.

            ## 6. Generate a professional, helpful reply that addresses the comment appropriately
            
            - If requirements were implemented, explain what was done and how it addresses the comment.
            - If no requirements existed, provide a helpful response explaining the situation.
          EO_Instructions
          constraints: <<~EO_Constraints
            - You are in read-only mode.
            - Do NOT modify or write any file.
            - The implementation work is already complete (captured in the artifacts).
            - ONLY focus on addressing the specific comment of the `ARTIFACT_OPEN_COMMENT_FOR_REPLY` artifact appropriately.
            - Do NOT answer or reply to any other comment.
            - You already have ALL the information required.
            - You MUST NOT ask follow-up questions.
            - You MUST NOT ask for user confirmation.
          EO_Constraints
        )
      end

      # Define a step that can be serialized and resumed.
      # This will store the state of this step in the file system.
      # If this step was already executed, skip it and update its artifacts from the file system store.
      #
      # Parameters::
      # * *name* (Symbol): Step name
      # * Proc: The code called for this step
      def step(name)
        if @run_id.nil?
          yield
        else
          step_dir = ".x-aeon_agents/runs/#{@run_id}/#{name}"
          step_file = "#{step_dir}/step.json"
          if File.exist?(step_file) && JSON.parse(File.read(step_file), symbolize_names: true)[:executed]
            # This step was already executed
            # Read all the artifacts
            @artifacts.replace(Dir.glob("#{step_dir}/*.md").to_h { |file| [File.basename(file, '.md').to_sym, File.read(file)] })
            log_debug "[Step #{name}] - Executed - #{@artifacts.size} artifacts read from persistence: #{@artifacts.keys.join(', ')}"
          else
            yield
            FileUtils.mkdir_p(step_dir)
            # Serialize all the artifacts
            @artifacts.each do |artifact_name, artifact_content|
              File.write("#{step_dir}/#{artifact_name}.md", artifact_content)
            end
            # Mark the step as executed
            File.write("#{step_dir}/step.json", { executed: true }.to_json)
            log_debug "[Step #{name}] - Executed - Stored #{@artifacts.size} artifacts in persistence: #{@artifacts.keys.join(', ')}"
          end
        end
      end

      # Setup an agents runner.
      # This method is re-entrant, meaning it can be called multiple times within the same execution context.
      # If a runner is already initialized, it will reuse the existing runner and artifacts.
      #
      # Parameters::
      # * *run_id* (String or nil): The run ID, or nil if persistence is not needed [default = nil]
      # * Proc: Code called with the runner setup
      def with_runner(run_id = nil)
        # If runner is already initialized, reuse existing runner and artifacts
        unless @artifacts
          # Initialize new runner and artifacts
          @run_id = run_id
          @artifacts = {}
        end
        yield
      end

      # Run an agent with a prompt.
      #
      # Parameters::
      # * *agent* (::Agents::Agent): The agent to run
      # * *prompt* (String): Additional prompt [default = '']
      # Result::
      # * String: The result output
      def run(agent, prompt = '')
        agent.params[:artifacts][:store] = @artifacts
        puts
        puts "===== #{agent.name}..."
        raw_response = nil
        agents_runner = ::Agents::AgentRunner.new([agent])
        agents_runner.on_llm_call_complete { |_agent_name, _model, response, _context_wrapper| raw_response = response.raw }
        result = agents_runner.run(prompt)
        puts "===== #{agent.name} - Total cost: $#{(raw_response[:usage] || {}).values.map { |stats| stats[:cost] || 0 }.sum }" unless raw_response.nil?
        raise "Error: #{result.error}\n#{result.error.backtrace.join("\n")}" unless result.error.nil?
        # Keep user's feedback in an artifact
        unless agent.params[:agent][:asks].empty?
          @artifacts[:user_feedbacks] = <<~EO_Artifact if @artifacts[:user_feedbacks].nil?
            The following is a conversation log.
            Each section is independent and labeled by speaker.
            Do not merge messages across roles.

          EO_Artifact
          @artifacts[:user_feedbacks] << <<~EO_Artifact
            ## Conversation between Agent: #{agent.name} and User
            
            #{
              agent.params[:agent][:asks].map do |ask|
                <<~EO_Ask
                  ### Agent: #{agent.name}
                  
                  ```
                  #{ask[:question]}
                  ```
                  
                  ### User
                  
                  ```
                  #{ask[:feedback]}
                  ```

                EO_Ask
              end.join
            }

          EO_Artifact
        end
        # Keep the log of the agent's run in an artifact
        @artifacts[:agents_run] = '' if @artifacts[:agents_run].nil?
        @artifacts[:agents_run] << "* #{agent.name}: #{agent.model}\n"
        result.output
      end

      # Create a Cline agent.
      # Artifacts are defined with these properties:
      # * *name* (Symbol): Artifact's name
      # * *description* (String): Artifact's description
      # * *to_be_reviewed* (Boolean): Does this artifact need user review during output? [default: false]
      #
      # Parameters::
      # * *name* (String): Agent name [default: 'Executor']
      # * *role* (String): Agent's role [default: "You are a #{name} agent"]
      # * *objective* (String): Agent's objective [default: '']
      # * *instructions* (String): Agent's system instructions [default: '']
      # * *constraints* (String): Constraints to be respected [default: '']
      # * *input_artifacts* (Array<Hash>): Set of artifacts this agent expects as input [default: []]
      # * *output_artifacts* (Array<Hash>): Set of artifacts this agent is expected to output [default: []]
      # * *model* (String): Model to be used [default: Configuration.config[:default_cline_model]]
      # * *plan_mode* (Boolean): Are we executing in Plan mode? [default: false]
      # * *config* (Hash): Cline config to be used [default: Configuration.config[:default_cline_config]]
      # * *cli_args* (String): Cline CLI additional arguments [default: Configuration.config[:default_cline_cli_args]]
      # * *skills* (Array<String>): List of skills to be associated to this agent [default: Configuration.config[:default_cline_skills]]
      def cline_agent(
        name: 'Executor',
        role: "You are a #{name} agent",
        objective: '',
        instructions: '',
        constraints: '',
        input_artifacts: [],
        output_artifacts: [],
        model: Configuration.config[:default_cline_model],
        plan_mode: false,
        config: Configuration.config[:default_cline_config],
        cli_args: Configuration.config[:default_cline_cli_args],
        skills: Configuration.config[:default_cline_skills]
      )
        ::Agents::Agent.new(
          model:,
          name:,
          params: {
            agent: {
              name:,
              role:,
              objective:,
              constraints:,
              asks: []
            },
            artifacts: {
              input: input_artifacts,
              output: output_artifacts
            },
            cline: {
              plan_mode:,
              config:,
              cli_args:,
              skills:
            }
          },
          instructions: system_instructions(name:, instructions:)
        )
      end

      # Compute the system instructions as a String from the original instructions and other agent variables that may affect it
      #
      # Parameters::
      # * *name* (String): Agent name
      # * *instructions* (Object): Original instructions given to the agent
      #   Here are the possible kinds of instructions:
      #   * Array<Object>: List of instruction descriptions that should be appended
      #   * Object: Individual instruction description.
      #   An individual instruction can be one of the following:
      #     * Hash<Symbol,Object>: A structure describing the instructions
      #     * String: Direct instructions to be used (equivalent to { text: instructions })
      #     Here is the list of keys that can define different instructions:
      #       * *text* (String): The instructions are given as text directly.
      #       * *ordered_list* (Array<String>): The instructions are a precise list of steps to perform.
      #       Several keys can be used in the same Hash, and they will be treated in the order in the Hash.
      # Result::
      # * String: The resulting instructions as a string
      def system_instructions(name:, instructions:)
        # Normalize instructions
        instructions = (instructions.is_a?(Array) ? instructions : [instructions]).
          map { |instruction_desc| instruction_desc.is_a?(Hash) ? instruction_desc : { text: instruction_desc } }

        # Convert the list of instructions into a nice string
        idx_checklist = 0
        instructions.map do |instruction_desc|
          instruction_desc.map do |instruction_kind, instruction|
            case instruction_kind
            when :text
              instruction
            when :ordered_list
              checklist_name = "#{name}-#{idx_checklist}"
              idx_checklist += 1
              <<~EO_Instructions
                ## Sequential steps to follow

                #{GenHelpers.init_skill_checklist(checklist_name)}

                #{
                  # Consider each element of the list as a potential markdown section, with the first line being the title.
                  instruction.map.with_index do |markdown_section, step_number|
                    lines = markdown_section.each_line.to_a
                    "### #{step_number + 1}. #{lines.first}#{lines[1..-1].join}"
                  end.join("\n\n")
                }

                #{GenHelpers.validate_skill_checklist(checklist_name)}
              EO_Instructions
            else
              raise "Unknown instruction kind: #{instruction_kind}"
            end
          end
        end.flatten(1).join("\n\n")
      end

      # Get all the replies of a given comment.
      # Replies are:
      # * all the comments that have this comment as a direct reply,
      # * plus the next (closest next creation date) comment that replied to the parent of the given comment,
      # * plus all the replies of those replies (recursively).
      #
      # Parameters::
      # * *comments* (Array<Hash>): All comments in the thread
      # * *comment* (Hash): The comment to check for replies
      # Result::
      # * Array<Hash>: List of all the replies
      def comment_replies(comments, comment)
        comment_id = comment[:databaseId]
        # All direct replies
        replies = comments.select { |c| c.dig(:replyTo, :databaseId) == comment_id }
        # All replies to the same parent, sorted by creation date
        parent_comment_id = comment.dig(:replyTo, :databaseId)
        unless parent_comment_id.nil?
          created_at = Time.parse(comment[:createdAt])
          next_parent_reply = comments.
            select { |c| c.dig(:replyTo, :databaseId) == parent_comment_id && Time.parse(c[:createdAt]) > created_at }.
            sort_by { |c| c[:created_at] }.
            first
          replies << next_parent_reply unless next_parent_reply.nil?
        end
        replies.map { |c| [c] + comment_replies(comments, c) }.flatten(1)
      end

    end

  end

end
