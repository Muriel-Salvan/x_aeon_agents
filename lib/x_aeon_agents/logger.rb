require 'time'
require 'human_number'
require 'tty-cursor'
require 'tty-table'

# Load the HumanNumber locale files, as it does not do it automatically.
# TODO: Remove this when human_number will be fixed.
I18n.load_path += Dir[File.join(Gem::Specification.find_by_name('human_number').gem_dir, 'lib', 'locales', '*.yml')]

module XAeonAgents
  # Mixin adding logging capabilities
  module Logger
    class << self
      # @return [Boolean] Global debug switch.
      attr_accessor :debug

      # @return [TTY::Cursor] Global Cursor instance
      attr_accessor :cursor

    end
    self.cursor = TTY::Cursor

    # Maximum size of debug messages printed for progress, in characters
    DEBUG_MESSAGE_MAX_SIZE = 80

    # Size of the tokens progress bar displayed in status, in characters
    STATUS_BAR_SIZE = 20

    # Log a message
    #
    # @param message [String, nil] Message to be displayed, or nil if the message is given lazily through a code block
    # @param level [Symbol] Message level
    # @yield [#call -> String] Optional code returning a [String] for lazy evaluation
    # @yieldreturn [String] The message to be displayed
    def log(message, level: :info)
      message = yield if block_given?
      log_line = "[#{Time.now.utc.strftime('%F %T')}] - [#{level.to_s[0].upcase}] - #{message}"
      if level != :debug || Logger.debug
        say log_line
      else
        # Put debug logs just as the last line, just to show activity without putting too much on screen.
        log_output(message.strip.gsub("\n", ' ')[0..(DEBUG_MESSAGE_MAX_SIZE - 1)], new_line: false)
      end
    end

    # Log a debug message
    #
    # @param message [String] Message to log.
    def log_debug(message)
      log(message, level: :debug)
    end

    # Log a warn message
    #
    # @param message [String] Message to log.
    def log_warn(message)
      log(message, level: :warn)
    end

    # Say a message to the user (puts on stdout)
    #
    # @param message [String] Message to say.
    def say(message = '')
      log_output(message)
    end

    private

    # Make sure the correct line separator is used depending on the OS.
    # Commands using WSL can mess this up, so we enforce it.
    LINE_SEPARATOR = Gem.win_platform? ? "\r\n" : "\n"

    # Output a given line to stdout.
    # Handle the case when we are in TTY or not.
    # - If in a TTY: Output the line with padding and display a status if any at the bottom.
    # - Else: Output the line, unless it shouldn't have a new line at the end (meaning it was a debug line not supposed to stay on screen).
    #
    # @param message [String] The message to output
    # @param new_line [Boolean] Should we insert a new line or get back at the line start after this message?
    def log_output(message, new_line: true)
      if $stdout.tty?
        status_string = build_status_string.strip
        unless status_string.empty?
          @last_status_size ||= 0
          # Go back to where the log line should start.
          nbr_lines_rewind = @last_status_size + (@previous_line_debug ? 1 : 0)
          print Logger.cursor.up(nbr_lines_rewind) if nbr_lines_rewind.positive?
          # Shift to the bottom as many lines as our log lines have, so that status stays below.
          nbr_lines_to_log = message.count("\n") + (@previous_line_debug ? 0 : 1)
          print "\e[#{nbr_lines_to_log}L" if nbr_lines_to_log.positive?

          # Pad potential stdout line with spaces to remove potential debug messages that could have been longer than this message.
          $stdout.write "#{message}#{' ' * [0, DEBUG_MESSAGE_MAX_SIZE - message.size].max}#{LINE_SEPARATOR}"

          # Keep an extra line between the real logs and the status
          $stdout.write "#{LINE_SEPARATOR}#{status_string}#{LINE_SEPARATOR}"
          @last_status_size = status_string.count("\n") + 2
          @previous_line_debug = !new_line
        end
        $stdout.flush
      elsif new_line
        $stdout.write "#{message}#{LINE_SEPARATOR}"
        $stdout.flush
      end
    end

    # Build a nice multi-line String displaying the status of all steps of all runs of all agents.
    # Display the hierarchy of steps with their status, and for the ones having usage information:
    # cost, context tokens usage progress bar and the agent's full name.
    #
    # @return [String] Multi-line status string, or empty String if there is no status to display
    def build_status_string
      # Get all runs from all agents, and sort the root ones per created_at property of their first step.
      # Make them as if they were called in 1 run of a virtual root agent that used step_agent for each one of those runs.
      # Extract and normalize the data for logging
      steps_run_map = proc do |step_run_info|
        {
          step_name: step_run_info[:step_name],
          # Position of the step in the hierarchy of steps (empty for the virtual root nodes).
          # It is used to display the hierarchy in the status.
          index: step_run_info[:index],
          status: step_run_info[:status],
          agent: step_run_info[:agent],
          # If the run_info is not given, it means we are dealing with a child (from step or step_agent)
          #   and those will only have 1 run maximum.
          run_info: step_run_info[:run_info] || step_run_info[:agent]&.runs_info&.first,
          children: step_run_info[:children].map(&steps_run_map)
        }
      end
      status_info = AgentDefaults.root_agents.map do |root_agent|
        root_agent.runs_info.map.with_index do |run_info, idx_run|
          root_step = {
            step_name: :"#{root_agent.name}-#{idx_run}",
            index: [],
            created_at: run_info.started_at,
            agent: root_agent,
            run_info:,
            children: []
          }
          if run_info.respond_to?(:steps) && !run_info.steps.empty?
            root_step.merge!(
              status: run_info.steps.last[:status],
              children: run_info.steps
            )
          end
          root_step
        end
      end.flatten(1).sort_by { |step_run_info| step_run_info[:created_at] }.map(&steps_run_map)

      # run_info can have a usage property containing the following Hash:
      # {
      #   cost: usages.sum { |usage| usage.cost || 0.0 },
      #   context_tokens: usages.last&.context_tokens,
      #   context_tokens_limit: usages.last&.context_tokens_limit
      # }
      # Create a nice multi-line String logging the status with alignment and hierarchy, like this:
      # DeveloperAgent           | ...    |
      # +- setup_requirements    | Cached |
      # +- PlannerAgent          | OK     | $2.50 | [1.5K |==---------| 1MB] - Cline deepseek/deepseek-v4
      # |  +- PlanGeneratorAgent | OK     | $2.50 | [ 50K |======-----| 1MB] - Cline deepseek/deepseek-v4
      # +- CoderAgent            | ...    | $2.50 | [ 50K |======-----| 1MB] - Cline deepseek/deepseek-v4
      nodes = status_nodes(status_info)
      usage_displays = nodes.map { |node| status_usage_display(node) }
      used_displays = usage_displays.compact
      # Compute the width of the tokens and limit numbers, to align them within the progress blocks
      tokens_width = used_displays.map { |used_display| used_display[:tokens].size }.max || 0
      limit_width = used_displays.map { |used_display| used_display[:limit].size }.max || 0
      rows = nodes.zip(usage_displays).map do |node, usage_display|
        [
          status_hierarchy_name(node),
          node[:status].to_s,
          usage_display ? usage_display[:cost] : '',
          usage_display ? status_progress_block(usage_display, tokens_width, limit_width) : '',
          node[:agent].respond_to?(:full_name) ? node[:agent].full_name : ''
        ]
      end
      return '' if rows.empty?

      render_status_table(rows)
    end

    # Flatten the tree of step run information into a list of nodes, in display order.
    #
    # @param status_info [Array<Hash>] Tree of step run information
    # @return [Array<Hash>] Flattened list of nodes
    def status_nodes(status_info)
      status_info.flat_map do |step_run_info|
        [step_run_info] + status_nodes(step_run_info[:children])
      end
    end

    # Get the hierarchical name of a step, with prefixes showing its depth in the hierarchy of steps.
    #
    # @param node [Hash] Step run information node
    # @return [String] Hierarchical name
    def status_hierarchy_name(node)
      depth = (node[:index] || []).size
      prefix = depth.zero? ? '' : "#{'|  ' * (depth - 1)}+- "
      "#{prefix}#{node[:step_name]}"
    end

    # Get the usage display information of a step's run, if any.
    #
    # @param node [Hash] Step run information node
    # @return [Hash, nil] The usage display information, or nil if there is no usage information:
    #   * *cost* (String): Formatted monetary cost of the run
    #   * *tokens* (String): Formatted number of context tokens
    #   * *limit* (String): Formatted number of context tokens limit
    #   * *bar* (String): Progress bar of the context tokens usage, sized to STATUS_BAR_SIZE
    def status_usage_display(node)
      run_info = node[:run_info]
      usage = run_info.respond_to?(:usage) ? run_info.usage : nil
      return nil unless usage

      tokens = usage[:context_tokens] || 0
      tokens_limit = usage[:context_tokens_limit] || 0
      filled_size = tokens_limit.positive? ? (tokens * STATUS_BAR_SIZE / tokens_limit).clamp(0, STATUS_BAR_SIZE) : 0
      {
        cost: HumanNumber.currency(usage[:cost] || 0.0, currency_code: 'USD'),
        tokens: HumanNumber.human_number(tokens, max_digits: 2),
        limit: HumanNumber.human_number(tokens_limit, max_digits: 2),
        bar: "#{'=' * filled_size}#{'-' * (STATUS_BAR_SIZE - filled_size)}"
      }
    end

    # Get the progress block cell displaying the context tokens usage, with aligned numbers.
    #
    # @param usage_display [Hash] Usage display information (see #status_usage_display)
    # @param tokens_width [Integer] Width to align the tokens number
    # @param limit_width [Integer] Width to align the limit number
    # @return [String] The progress block cell
    def status_progress_block(usage_display, tokens_width, limit_width)
      "[#{usage_display[:tokens].rjust(tokens_width)} |#{usage_display[:bar]}| #{usage_display[:limit].ljust(limit_width)}]"
    end

    # Render the status rows as an aligned table, without borders, just column separators.
    #
    # @param rows [Array<Array<String>>] Rows of 5 cells: hierarchical name, status, cost, progress block, model
    # @return [String] Multi-line table
    def render_status_table(rows)
      TTY::Table.new(rows).render do |renderer|
        # Never rotate the table to vertical orientation, whatever the terminal width is
        renderer.width = Float::INFINITY
        renderer.border do
          center ' | '
          top ''
          bottom ''
          left ''
          right ''
        end
      end.split("\n").map do |line|
        # Remove trailing empty columns, as some rows don't have usage or model information
        line.rstrip.sub(/(?:\s*\|)+\z/, '').rstrip
      end.join(LINE_SEPARATOR)
    end
  end
end
