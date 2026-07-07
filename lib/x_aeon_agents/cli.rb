require 'thor'

module XAeonAgents
  # Main X-Aeon Agents CLI
  class Cli < Thor
    # Global options
    class_option :session_id, type: :string, desc: 'Session ID for persistence'
    class_option :debug, type: :boolean, default: false, desc: 'Enable debug mode'

    # --------------------------------------------------------------------------- #
    # review-comments: Address Pull Request review comments
    # --------------------------------------------------------------------------- #

    desc 'review-comments PULL_REQUEST_NUMBER', 'Address review comments on a GitHub Pull Request'
    long_desc <<~LONGDESC
      Reads Pull Request comments addressed to the agent, improves or fixes
      the code based on those comments, and replies to each one. The Pull
      Request is identified by its number in the current GitHub repository.

      Examples:

        $   xaa review-comments 42

        $   xaa review-comments 42 --session-id my-session
    LONGDESC
    # Addresses review comments on a GitHub Pull Request.
    #
    # @param pull_request_number [Integer] The GitHub Pull Request number to process
    def review_comments(pull_request_number)
      Agents::ReviewResolverAgent.new(session_id: options[:session_id]).run(
        pull_request_number: Integer(pull_request_number)
      )
    end

    # --------------------------------------------------------------------------- #
    # commit: Commit staged changes with an AI-generated message
    # --------------------------------------------------------------------------- #

    desc 'commit', 'Commit staged changes with an AI-generated commit message'
    long_desc <<~LONGDESC
      Analyzes the currently staged changes and generates a meaningful commit
      message before committing.

      Example:

        $   xaa commit
    LONGDESC
    # Commits staged changes with an AI-generated commit message.
    def commit
      Agents::CommitterAgent.new(session_id: options[:session_id]).run
    end

    # --------------------------------------------------------------------------- #
    # generate-readme: Generate or update the project README
    # --------------------------------------------------------------------------- #

    desc 'generate-readme', 'Generate a comprehensive README from the codebase'
    long_desc <<~LONGDESC
      Uses AI to analyze the project and generate a README file with the
      following sections (all enabled by default):

        --about
        --quick-start
        --requirements
        --features
        --public-api
        --documentation
        --how-it-works
        --development
        --contributing
        --license

      Disable individual sections with --no-<section>.

      Examples:

        $   xaa generate-readme

        $   xaa generate-readme --no-features --no-license --session-id my-session

        $   xaa generate-readme --readme-file-path /path/to/custom/README.md
    LONGDESC
    option :about, type: :boolean, default: true, desc: 'Generate the About section'
    option :quick_start, type: :boolean, default: true, desc: 'Generate the Quick Start section'
    option :requirements, type: :boolean, default: true, desc: 'Generate the Requirements section'
    option :features, type: :boolean, default: true, desc: 'Generate the Features section'
    option :public_api, type: :boolean, default: true, desc: 'Generate the Public API section'
    option :documentation, type: :boolean, default: true, desc: 'Generate the Documentation section'
    option :how_it_works, type: :boolean, default: true, desc: 'Generate the How It Works section'
    option :development, type: :boolean, default: true, desc: 'Generate the Development section'
    option :contributing, type: :boolean, default: true, desc: 'Generate the Contributing section'
    option :license, type: :boolean, default: true, desc: 'Generate the License section'
    option :readme_file_path, type: :string, default: nil, desc: 'Path to the README file to generate or update'
    # Generates or updates the project README file.
    def generate_readme
      agent_kwargs = {
        gen_about: options[:about],
        gen_quick_start: options[:quick_start],
        gen_requirements: options[:requirements],
        gen_features: options[:features],
        gen_public_api: options[:public_api],
        gen_documentation: options[:documentation],
        gen_how_it_works: options[:how_it_works],
        gen_development: options[:development],
        gen_contributing: options[:contributing],
        gen_license: options[:license]
      }
      agent_kwargs[:readme_file_path] = options[:readme_file_path] if options[:readme_file_path]
      Agents::ReadmeGeneratorAgent.new(session_id: options[:session_id]).run(**agent_kwargs)
    end

    # --------------------------------------------------------------------------- #
    # generate-skills: Generate skill files from ERB templates
    # --------------------------------------------------------------------------- #

    desc 'generate-skills', 'Generate skill files from ERB templates in skills.src/'
    long_desc <<~LONGDESC
      Processes the skills.src/ directory and writes generated skill files to
      the output directory (default: skills/).  ERB templates (.erb) are
      evaluated; all other files are copied as-is.

      Examples:

        $   xaa generate-skills

        $   xaa generate-skills --output-dir custom_skills
    LONGDESC
    option :output_dir, type: :string, default: 'skills', desc: 'Output directory for generated skills'
    option(
      :skill,
      type: :string,
      repeatable: true,
      desc: 'Skill name(s) to generate. Can be repeated: --skill name1 --skill name2 or comma-separated: --skill name1,name2. Omit to generate all skills.'
    )
    # Generates skill files from ERB templates in skills.src/.
    #
    # @note Exits with status 1 if skill generation fails
    def generate_skills
      result = Agents::SkillGeneratorAgent.new(session_id: options[:session_id]).run(
        output_dir: options[:output_dir],
        skill_names: options[:skill]
      )
      exit 1 unless result[:success]
    end

    # --------------------------------------------------------------------------- #
    # implement-issue: Implement a GitHub issue
    # --------------------------------------------------------------------------- #

    desc 'implement-issue ISSUE_NUMBER', 'Implement a GitHub issue using AI'
    long_desc <<~LONGDESC
      Reads the content (and comments) of a GitHub issue and delegates the
      implementation to the Developer agent.  The agent commits changes and
      opens a Pull Request automatically.

      Examples:

        $   xaa implement-issue 15

        $   xaa implement-issue 15 --session-id my-session
    LONGDESC
    # Implements a GitHub issue using AI.
    #
    # @param github_issue_number [Integer] The GitHub issue number to implement
    def implement_issue(github_issue_number)
      Agents::IssueImplementerAgent.new(
        commit: true,
        pull_request: true,
        session_id: options[:session_id]
      ).run(github_issue_number: Integer(github_issue_number))
    end

    # --------------------------------------------------------------------------- #
    # implement: Implement arbitrary requirements
    # --------------------------------------------------------------------------- #

    desc 'implement REQUIREMENTS', 'Implement given requirements with AI'
    long_desc <<~LONGDESC
      Pass free-form requirements to the Developer agent, which will analyze
      the codebase and produce the requested changes.

      Examples:

        $   xaa implement "Add authentication middleware"

        $   xaa implement "Refactor the database layer" --commit --pr --session-id my-session
    LONGDESC
    option :commit, type: :boolean, default: false, desc: 'Commit files at every step'
    option :pr, type: :boolean, default: false, desc: 'Create a GitHub Pull Request for the changes'
    # Implements arbitrary requirements using AI.
    #
    # @param requirements [String] Free-form requirements describing the desired changes
    def implement(requirements)
      Agents::DeveloperAgent.new(
        commit: options[:commit],
        pull_request: options[:pr],
        session_id: options[:session_id]
      ).run(requirements:)
    end

    # --------------------------------------------------------------------------- #
    # interpret-diffs: Summarize current git diffs
    # --------------------------------------------------------------------------- #

    desc 'interpret-diffs [BASE]', 'Summarize git diffs relative to a base ref'
    long_desc <<~LONGDESC
      Produces a one-line summary and a description of the intent behind the
      changes in the working tree relative to BASE (default: HEAD).

      Examples:

        $   xaa interpret-diffs

        $   xaa interpret-diffs main

        $   xaa interpret-diffs HEAD~3
    LONGDESC
    # Summarizes current git diffs relative to a base ref.
    #
    # @param base [String] Git reference to diff against
    def interpret_diffs(base = 'HEAD')
      output = Agents::GitDiffInterpreterAgent.new(session_id: options[:session_id]).run(git_ref_base: base)
      puts <<~EO_OUTPUT
        ===== Code diffs interpretation:

        #{output[:one_line_summary].strip}

        #{output[:change_intent].strip}
      EO_OUTPUT
    end

    # --------------------------------------------------------------------------- #
    # prompt: Send a one-shot prompt to the AI agent
    # --------------------------------------------------------------------------- #

    desc 'prompt PROMPT', 'Send a one-shot prompt to the AI agent and print the response'
    long_desc <<~LONGDESC
      Executes a single prompt against the free simple AI model and prints
      the last message of the conversation.

      Examples:

        $   xaa prompt "What is the capital of France?"

        $   xaa prompt "Explain this code: puts 'hello'"
    LONGDESC
    # Sends a one-shot prompt to the AI agent and prints the response.
    #
    # @param user_prompt [String] The prompt text to send to the AI agent
    def prompt(user_prompt)
      agent = Agents::ExecutorAgent.new(session_id: options[:session_id], **Models.free_simple)
      agent.run(user_instructions: user_prompt)
      puts agent.conversation.last[:message]
    end

    # --------------------------------------------------------------------------- #
    # install-skills: Install skills from the .skills manifest
    # --------------------------------------------------------------------------- #

    desc 'install-skills', 'Install skills and their dependencies from the .skills manifest'
    long_desc <<~LONGDESC
      Reads the .skills manifest file and installs every listed skill,
      together with their recursively-resolved dependencies.

      Example:

        $   xaa install-skills

        $   xaa install-skills --agent cline
    LONGDESC
    option :agent, type: :string, default: 'cline', desc: 'Agent name to be used to install skills'
    # Installs skills and their dependencies from the .skills manifest.
    def install_skills
      Agents::SkillInstallerAgent.new(session_id: options[:session_id]).run(
        agent: options[:agent].to_sym
      )
    end

    # --------------------------------------------------------------------------- #
    # start-task: Open a new git worktree for a task
    # --------------------------------------------------------------------------- #

    desc 'start-task', 'Open a new git worktree for a feature branch'
    long_desc <<~LONGDESC
      Interactive command that prompts for a branch name, creates the branch
      (if it does not exist), sets up a git worktree in .worktrees/, pushes
      the branch upstream, and opens it in VSCodium.

      Example:

        $   xaa start-task
    LONGDESC
    # Opens a new git worktree for a feature branch.
    def start_task
      puts 'Branch name:'
      branch = $stdin.gets.strip
      Agents::TaskStarterAgent.new(session_id: options[:session_id]).run(branch_name: branch)
    end

    # --------------------------------------------------------------------------- #
    # Exit on failure for consistent scripting
    # --------------------------------------------------------------------------- #

    # Returns whether to exit on command failure.
    #
    # @return [Boolean] Always returns true so Thor exits with a non-zero status on command failure
    def self.exit_on_failure?
      true
    end

    no_commands do
      # Initializes the CLI and applies global configuration from options.
      #
      # @param args [Array<Object>] Arguments forwarded to Thor's constructor
      def initialize(*)
        super
        # Handle all the global setup from options
        Config.debug = options[:debug]
      end
    end
  end
end
