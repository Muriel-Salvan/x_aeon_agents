# Configuration

`x_aeon_agents` works with environment variables alone. When you need more control, an optional Ruby
configuration file adds secret retrieval, project commands, worktree hooks and per-agent settings.

- [The configuration file](#the-configuration-file)
  - [Where the file is loaded from](#where-the-file-is-loaded-from)
  - [Available DSL methods](#available-dsl-methods)
- [`XAeonAgents::Config`](#xaeonagentsconfig)
- [`XAeonAgents::Logger`](#xaeonagentslogger)

## The configuration file

The file is named `.x_aeon_agents.rb` and is evaluated at the start of every `xaa` command. It can also
be loaded manually with `XAeonAgents::Config.load`.

### Where the file is loaded from

Files are looked up in the following order, from the lowest priority (first evaluated) to the highest
priority — so higher-priority settings override lower-priority ones:

1. `~/.x_aeon_agents.rb` — global, per-user settings.
2. `./.x_aeon_agents.rb` — project-level settings (current directory).
3. The path given by the `X_AEON_AGENTS_CONFIG` environment variable, if set — overrides both.

> [!NOTE]
> All existing files are evaluated in this order (not just the first one found), and explicit CLI flags
> (`--debug`, `--interactive`) still override everything. The file is evaluated in a cleanroom: only the
> DSL methods below are exposed at its top level, but regular Ruby code works inside the blocks given to
> those methods.

### Available DSL methods

| Method | Description |
| --- | --- |
| `debug(value)` | Enable debug logging |
| `interactive(value)` | Enable interactive content reviews (defaults to `true`) |
| `data_dir 'dir'` | Data directory where X-Aeon Agents stores its data |
| `cline_api_key { ... }` / `openrouter_api_key { ... }` / `github_token { ... }` | Define the code retrieving a secret |
| `setup_project { ... }` | Steps to install the project's dependencies in a fresh worktree |
| `test_project_cmd 'cmd'` | Command line running the project's test suite |
| `on_open_worktree { \|dir\| ... }` | Callback executed when a worktree is opened |
| `configure_agent(:AgentClass) { \|cfg\| ... }` | Default kwargs for agents of a given class |

#### `debug(value)`

Set the debug mode:

```ruby
debug true
```

#### `interactive(value)`

Set the interactive mode. When disabled, content reviews (commit messages, implementation plans…) are
accepted as-is, without opening any file nor prompting the user. Defaults to `true`:

```ruby
interactive false
```

#### `data_dir(path)`

Set the data directory where X-Aeon Agents stores its data (sessions, temporary files). Defaults to
`.x_aeon_agents`:

```ruby
data_dir '/var/lib/x_aeon_agents'
```

#### Secret retrieval blocks

`cline_api_key`, `openrouter_api_key` and `github_token` take a block returning the secret value. Each
block is evaluated lazily, only when the secret is needed, and its result is memoized. Secrets are
resolved with the precedence **explicit setter → `ENV` variable → config DSL block** (see
[`XAeonAgents::Config`](#xaeonagentsconfig)):

```ruby
github_token { File.read("#{Dir.home}/.github_token").strip }
```

#### `setup_project { ... }`

Define the steps to execute in a fresh git worktree to install the project's dependencies (used by
`xaa start-task`). The block is evaluated only when a fresh worktree is created, with the current
directory set to the worktree:

```ruby
setup_project { system 'bundle install' }
```

#### `test_project_cmd(command_line)`

Define the command line running the project's test suite, used by `xaa implement` to validate code
changes. If not set, no tests are run by the implement command:

```ruby
test_project_cmd 'bundle exec rspec --format=documentation'
```

#### `on_open_worktree { |dir| ... }`

Define a callback executed every time a worktree is opened by `xaa start-task` (freshly created or
already existing), after the branch has been pushed to the remote. It receives the worktree's directory:

```ruby
on_open_worktree { |dir| system "code \"#{dir}\"" }
```

#### `configure_agent(agent_class_name) { |agent_config| ... }`

Define the default kwargs to be merged when initializing agents of a given class (e.g. `:CoderAgent`).
The block is evaluated every time an agent of this class is instantiated: it is given the currently
merged configuration (a Hash of kwargs that can be modified in place), and returns a Hash of additional
kwargs merged on top.

It is re-entrant: it can be called several times for the same class, from the same file or from
different ones (global, project, env-var designated), each call seeing the configuration accumulated by
the previous ones.

Typical kwargs keys (as used by the agent frameworks):

- `skills` — Array of skill names the agent should follow.
- `model` — LLM model to use (e.g. `'deepseek/deepseek-v4-flash'`).
- `cli_options` — Hash of options merged into the Cline CLI invocation (e.g. `plan: true`). Cline agents
  always get `timeout: 600` (10 minutes) and `retries: 5` by default; options given here supersede them
  option by option (`nil` disables one).
- `configure_global` — Proc given the Cline global settings to tweak. Whatever it configures, the Cline
  tools that X-Aeon agents don't use (agent spawning and team management tools) are always disabled, as
  is `ask_question` when `interactive` is off; lists are merged without duplicates.

```ruby
configure_agent(:PlanGeneratorAgent) do |agent_config|
  {
    skills: %w[applying-ruby-conventions enforcing-project-rules],
    model: 'deepseek/deepseek-v4-flash',
    cli_options: (agent_config[:cli_options] || {}).merge(plan: true),
    configure_global: proc { |global_settings| global_settings.disabled_tools = %w[editor run_commands] }
  }
end
```

This is how you make a workflow cheap: assign inexpensive models to the roles whose intelligence
matters least, and keep the expensive ones for planning and review. The
[example configuration](../.x_aeon_agents.example.rb) in this repository does exactly that.

## `XAeonAgents::Config`

Singleton module holding all X-Aeon Agents configuration (secrets, data directory, default Cline CLI
arguments, debug flag). All methods listed below are part of the `Public API` YARD group.

**Usecase** — configure credentials and options at once:

```ruby
require 'x_aeon_agents'

XAeonAgents::Config.configure(
  openrouter_api_key: ENV['OPENROUTER_API_KEY'],
  github_token: ENV['GITHUB_TOKEN'],
  debug: false
)
```

More details: [RubyDoc — XAeonAgents::Config](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config)

Public methods:

- `configure(**kwargs)` — set any configuration property. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#configure-class_method)
- `cline_api_key` / `cline_api_key=`, `openrouter_api_key` / `openrouter_api_key=`, `github_token` / `github_token=` — lazily-resolved secrets (ENV or config DSL). [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#cline_api_key-class_method)
- `data_dir` / `data_dir=` — data directory (`.x_aeon_agents` by default). [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#data_dir-class_method)
- `default_cline_cli_args` / `default_cline_cli_args=` — default Cline CLI arguments. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#default_cline_cli_args-class_method)
- `debug` / `debug=` — enable debug logging. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#debug-class_method)
- `interactive` / `interactive=` — enable interactive content reviews (defaults to true). [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#interactive-class_method)
- `config_paths` — candidate paths of the optional `.x_aeon_agents.rb` config file. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#config_paths-class_method)
- `logger` — the shared logger instance. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#logger-class_method)

## `XAeonAgents::Logger`

The shared status-aware logger used by all X-Aeon Agents components (accessible through
`XAeonAgents::Config.logger`). It inherits from the standard Ruby `Logger`; the methods below are part of
the public API, on top of the standard `::Logger` interface.

**Usecase** — write a log line, then dump a raw message:

```ruby
XAeonAgents::Config.logger.info 'Fetching repository metadata'
XAeonAgents::Config.logger << 'machine-readable output'
```

More details: [RubyDoc — XAeonAgents::Logger](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Logger)

Public methods:

- `add(severity, message = nil, progname = nil, &block)` — log a message with a given severity. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Logger#add-instance_method)
- `log(severity, message = nil, progname = nil, &block)` — alias of `add`. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Logger#log-instance_method)
- `<<(message)` — output a raw, unformatted message. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Logger#%3C%3C-instance_method)

