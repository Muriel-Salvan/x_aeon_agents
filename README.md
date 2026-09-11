<div align="center">

# x_aeon_agents

**Executable software-engineering workflows for coding agents** — a Ruby gem that packages composable AI agents behind an `xaa` CLI and a reusable library to automate everyday development workflows.

[![Build](https://github.com/Muriel-Salvan/x_aeon_agents/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/Muriel-Salvan/x_aeon_agents/actions/workflows/continuous_integration.yml)
[![Test Coverage](https://img.shields.io/codecov/c/gh/Muriel-Salvan/x_aeon_agents)](https://codecov.io/gh/Muriel-Salvan/x_aeon_agents)
[![GitHub stars](https://img.shields.io/github/stars/Muriel-Salvan/x_aeon_agents)](https://github.com/Muriel-Salvan/x_aeon_agents/stargazers)
[![License](https://img.shields.io/github/license/Muriel-Salvan/x_aeon_agents)](LICENSE)
[![Gem Version](https://img.shields.io/gem/v/x_aeon_agents)](https://rubygems.org/gems/x_aeon_agents)
[![Gem Total Downloads](https://img.shields.io/gem/dt/x_aeon_agents)](https://rubygems.org/gems/x_aeon_agents)

</div>

**x_aeon_agents** turns coding agents into participants in *explicit, repeatable and quality software-engineering processes* — instead of letting the agent invent its own workflow on the fly.

Powered by the `xaa` command-line interface (and usable as a **Ruby library** too), it packages a suite of composable AI agents that automate everyday development tasks:

- 📬 **Pull Request reviews** — automatically read, address and reply to GitHub review comments
- 📝 **Commit messages** — generate meaningful descriptions for your staged changes
- 🚀 **Issue implementation** — turn GitHub issues into working code and open Pull Requests
- 📚 **README generation** — build documentation sections straight from your codebase
- 🔍 **Git diff interpretation** — summarize what changed and why
- 🌿 **Task bootstrapping** — create git worktrees and feature branches in seconds
- 🔧 **Skill templating** — generate reusable agent workflows from ERB templates

Use it as a **⚡ CLI** in your terminal or as a **📦 library** inside your Ruby projects.

## Table of contents

- [Quick start](#quick-start)
  - [Prerequisites](#prerequisites)
  - [Install](#install)
  - [Configure](#configure)
  - [Use the CLI](#use-the-cli)
  - [Use as a library](#use-as-a-library)
- [Requirements](#requirements)
- [Features](#features)
- [Public API](#public-api)
  - [Executable: `xaa`](#executable-xaa)
  - [Config DSL file (`.x_aeon_agents.rb`)](#config-dsl-file-x_aeon_agentsrb)
  - [`XAeonAgents::Config`](#xaeonagentsconfig)
  - [`XAeonAgents::GenHelpers`](#xaeonagentsgenhelpers)
  - [`XAeonAgents::Logger`](#xaeonagentslogger)
- [Documentation](#documentation)
  - [Library public API](#library-public-api)
- [How it works](#how-it-works)
  - [Entry point 🚪](#entry-point-)
  - [Agents as composable workflows 🧩](#agents-as-composable-workflows-)
  - [Orchestration 🔗](#orchestration-)
  - [Configuration & providers 🔐](#configuration--providers-)
  - [Skills & ERB templating 📚](#skills--erb-templating-)
  - [Helpers 🛠️](#helpers-)
- [Development](#development)
  - [Prerequisites](#prerequisites-1)
  - [Clone and install dependencies](#clone-and-install-dependencies)
  - [Project layout](#project-layout)
  - [Running the test suite](#running-the-test-suite)
  - [Linting](#linting)
  - [Building skills from templates](#building-skills-from-templates)
  - [Common development tasks](#common-development-tasks)
  - [Packaging and release](#packaging-and-release)
- [Contributing](#contributing)
  - [🐛 Reporting issues](#-reporting-issues)
  - [🍴 Forking & branching](#-forking--branching)
  - [🧪 Running the tests](#-running-the-tests)
  - [🔀 Opening a Pull Request](#-opening-a-pull-request)
  - [🤖 CI & coverage](#-ci--coverage)
  - [🧹 Code style](#-code-style)
  - [✅ Before you submit](#-before-you-submit)
- [License](#license)
- [Ways skills are written](#ways-skills-are-written)
- [General principles](#general-principles)
- [Generating skills from ERB templates](#generating-skills-from-erb-templates)

## Quick start

### Prerequisites

- **Ruby** `>= 3.1` (RubyGems/Bundler required to install the gem)
- **Git** command-line client available in `PATH`
- **GitHub CLI (`gh`)** installed and authenticated for Pull Request / issue features
- An **OpenRouter API key** (`OPENROUTER_API_KEY`) to power the AI agents
- A **GitHub token** (`GITHUB_TOKEN`) for features that talk to GitHub
- Optionally a **Cline API key** (`CLINE_API_KEY`) when driving the Cline agent

### Install

Install the gem from RubyGems:

```bash
gem install x_aeon_agents
```

Or add it to your project's `Gemfile` and install with Bundler:

```ruby
gem 'x_aeon_agents'
```

```bash
bundle install
```

### Configure

Export the required credentials as environment variables (the CLI and library read them automatically):

```bash
export OPENROUTER_API_KEY="sk-or-..."
export GITHUB_TOKEN="ghp_..."
```

For fine-tuning, you can create an optional `.x_aeon_agents.rb` configuration file in your home directory (`~/.x_aeon_agents.rb` for global settings) or in the current project directory (for project-level settings). It is evaluated at the start of every `xaa` command. See the [Config DSL file](#config-dsl-file-x_aeon_agentsrb) section for the full DSL reference. For example, to enable debug logging and declare a secret retrieval block:

```ruby
debug true

openrouter_api_key do
  # Any Ruby code that returns the key
  File.read('/path/to/my/key').strip
end
```

### Use the CLI

The `xaa` command is installed alongside the gem. Run it from inside any Git repository.

Commit your staged changes with an AI-generated message:

```bash
xaa commit
```

Address GitHub Pull Request review comments (auto-detected from the current branch):

```bash
xaa review-comments
```

Push your branch and open a Pull Request:

```bash
xaa create-pr
```

Generate or update the project README from the codebase:

```bash
xaa generate-readme
```

Ask a quick one-off question to the AI agent:

```bash
xaa prompt "What is the capital of France?"
```

### Use as a library

Require the gem and configure it in your Ruby code:

```ruby
require 'x_aeon_agents'

XAeonAgents::Config.configure(
  openrouter_api_key: ENV['OPENROUTER_API_KEY'],
  github_token: ENV['GITHUB_TOKEN']
)

# Trigger agents programmatically
XAeonAgents::Agents::CommitterAgent.new.run
```

## Requirements

- **Operating system** — any platform supported by Ruby (Linux, macOS, Windows)
- **Ruby** `>= 3.1` (with RubyGems/Bundler) — the `xaa` CLI and the library are Ruby-based
- **Git** command-line client in `PATH` — the agents operate on repositories, branches, worktrees and commits
- **GitHub CLI (`gh`)** installed and authenticated — used by the Pull Request and comment skills to query and reply via `gh api`
- **A Git repository** — the `xaa` commands must be run from inside a Git repository
- **Network access** — to reach the OpenRouter and GitHub APIs
- **`GITHUB_TOKEN`** environment variable — a GitHub personal access token used by Octokit for API access
- **`OPENROUTER_API_KEY`** environment variable — an OpenRouter API key that powers the AI agents through RubyLLM
- **`CLINE_API_KEY`** environment variable (optional) — only required when driving the Cline agent integration

Each of these secrets can alternatively be retrieved by custom code declared in the [Config DSL file](#config-dsl-file-x_aeon_agentsrb).

## Features

**x_aeon_agents** provides a *`xaa`* command-line interface and a reusable Ruby library that package a suite of composable AI agents to automate everyday development workflows.

- 📬 **Pull Request review handling** — auto-detect the PR for the current branch, read agent-addressed comments, fix the code and reply to each thread
- 📝 **AI commit messages** — analyze staged changes and generate a meaningful message, with flexible staging strategies (`all`, `if_empty`, `none`)
- 🚀 **Automated Pull Request creation** — push the branch to GitHub and open a PR against a configurable base ref with an AI-written description
- 🐛 **GitHub issue implementation** — turn an issue (and its comments) into working code, committing changes and opening a PR automatically
- 🛠️ **Arbitrary requirement implementation** — pass free-form requirements to a Developer agent that plans, codes and tests the changes, optionally committing and opening a PR
- 📚 **README generation** — build a full README from the codebase with 10 toggleable sections (about, quick start, requirements, features, public API, documentation, how-it-works, development, contributing, license)
- 🔍 **Git diff interpretation** — summarize the working-tree changes and the intent behind them relative to any base ref
- 💬 **One-shot prompts** — send a single prompt to the AI agent and print the response
- 🔧 **Skill templating** — generate skill files from ERB templates in `skills.src/`, evaluating templates and copying assets to the output directory
- 📥 **Skill installation** — install skills and their recursively-resolved dependencies from a manifest for a chosen agent
- 🌿 **Task bootstrapping** — create a feature branch, set up a git worktree, push it upstream and open it in the editor, with `setup_project` and `on_open_worktree` hooks
- 🧩 **Composable agent framework** — orchestrating agents (planner ➜ coder ➜ tester ➜ committer ➜ documenter ➜ PR creator) built on `ai-agents`/`composable_agents`, backed by a Cline/OpenRouter provider via RubyLLM
- ⚙️ **Extensible config DSL** — optional `.x_aeon_agents.rb` file with secrets handling, per-agent model tuning (`configure_agent`) and a project test command
- 💾 **Session persistence & debugging** — global `--session-id` to resume AI conversations and a `--debug` flag for verbose logging
- 📦 **Reusable Ruby library** — require the gem and trigger agents programmatically (e.g. `Agents::CommitterAgent.new.run`)

## Public API

`x_aeon_agents` exposes one command-line executable (`xaa`) and a small Ruby library surface. Only the entry points below are part of the public API (the executable in `bin/` and the Ruby methods tagged with YARD's `Public API` group).

### Executable: `xaa`

The `bin/xaa` script is the CLI entry point: it boots the gem and dispatches the arguments to `XAeonAgents::Cli`. Run it from inside any Git repository.

**Usecase** — commit your staged changes with an AI-generated message:

```bash
xaa commit
```

Available commands:

| Command | Description |
| --- | --- |
| `xaa review-comments [PR_NUMBER]` | Read, address and reply to GitHub Pull Request review comments |
| `xaa commit` | Commit staged changes with an AI-generated message |
| `xaa create-pr` | Push the branch and create a GitHub Pull Request |
| `xaa implement-issue ISSUE_NUMBER` | Implement a GitHub issue with AI |
| `xaa implement REQUIREMENTS` | Implement free-form requirements with AI |
| `xaa interpret-diffs [BASE]` | Summarize git diffs relative to a base ref |
| `xaa generate-readme` | Generate or update the project README from the codebase |
| `xaa generate-skills` | Generate skill files from ERB templates in `skills.src/` |
| `xaa install-skills` | Install skills from the `.skills` manifest |
| `xaa start-task` | Create a feature branch, git worktree, and push it upstream |
| `xaa prompt PROMPT` | Send a one-shot prompt to the AI agent |

More details: [GitHub — bin/xaa](https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/bin/xaa) · [RubyDoc — XAeonAgents::Cli](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Cli)

### Config DSL file (`.x_aeon_agents.rb`)

The optional `.x_aeon_agents.rb` configuration file exposes a small Ruby DSL used to fine-tune X-Aeon Agents: retrieve secrets from custom sources, define project setup and testing commands, hook into the worktree lifecycle and tune the default settings of any agent class. It is evaluated at the start of every `xaa` command (and can be loaded manually with `XAeonAgents::Config.load`).

**Usecase** — retrieve a secret from a custom source, define the test suite command and tune the coding agent:

```ruby
openrouter_api_key { File.read('/path/to/my/key').strip }

test_project_cmd 'bundle exec rspec --format=documentation'

configure_agent(:CoderAgent) do
  { model: 'deepseek/deepseek-v4-flash' }
end
```

More details: [GitHub — .x_aeon_agents.example.rb](https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/.x_aeon_agents.example.rb)

#### Where the file is loaded from

Files are looked up in the following locations and evaluated from the lowest priority (first) to the highest one — so higher-priority settings override lower-priority ones:

1. `~/.x_aeon_agents.rb` — global, per-user settings
2. `./.x_aeon_agents.rb` — project-level settings (current directory)
3. The path given by the `X_AEON_AGENTS_CONFIG` environment variable, if set — overrides both

> [!NOTE]
> All existing files are evaluated in this order (not just the first one found), and explicit CLI flags (`--debug`) still override everything. The file is evaluated in a cleanroom: only the DSL methods below are exposed at its top level, but regular Ruby code works inside the blocks given to those methods.

#### Possible methods

| Method | Description |
| --- | --- |
| `debug(value)` | Enable debug logging |
| `cline_api_key { ... }` / `openrouter_api_key { ... }` / `github_token { ... }` | Define the code retrieving a secret |
| `setup_project { ... }` | Steps to install the project's dependencies in a fresh worktree |
| `test_project_cmd 'cmd'` | Command line running the project's test suite |
| `on_open_worktree { \|dir\| ... }` | Callback executed when a worktree is opened |
| `configure_agent(:AgentClass) { \|cfg\| ... }` | Default kwargs for agents of a given class |

- **`debug(value)`** — set the debug mode:

  ```ruby
  debug true
  ```

- **Secret retrieval blocks** — `cline_api_key`, `openrouter_api_key` and `github_token` take a block returning the secret value. Each block is evaluated lazily, only when the secret is needed, and its result is memoized. Secrets are resolved with the precedence *explicit setter ➜ `ENV` variable ➜ config DSL block* (see [`XAeonAgents::Config`](#xaeonagentsconfig)):

  ```ruby
  github_token { File.read("#{Dir.home}/.github_token").strip }
  ```

- **`setup_project { ... }`** — define the steps to execute in a fresh git worktree to install the project's dependencies (used by `xaa start-task`). The block is evaluated only when a fresh worktree is created, with the current directory set to the worktree:

  ```ruby
  setup_project { system 'bundle install' }
  ```

- **`test_project_cmd(command_line)`** — define the command line running the project's test suite, used by `xaa implement` to validate code changes. If not set, no tests are run by the implement command:

  ```ruby
  test_project_cmd 'bundle exec rspec --format=documentation'
  ```

- **`on_open_worktree { |dir| ... }`** — define a callback executed every time a worktree is opened by `xaa start-task` (freshly created or already existing), after the branch has been pushed to the remote. It is given the worktree's directory as parameter:

  ```ruby
  on_open_worktree { |dir| system "code \"#{dir}\"" }
  ```

- **`configure_agent(agent_class_name) { |agent_config| ... }`** — define the default kwargs to be merged when initializing agents of a given class (e.g. `:CoderAgent`). The block is evaluated every time an agent of this class is instantiated: it is given the currently merged configuration (a Hash of kwargs, that can be modified in place), and returns a Hash of additional kwargs merged on top. It is re-entrant: it can be called several times for the same class, from the same file or from different ones (global, project, env-var designated), each call seeing the configuration accumulated by the previous ones. Typical kwargs keys (as used by the agent frameworks):
  - `skills` — Array of skill names the agent should follow
  - `model` — LLM model to use (e.g. `'deepseek/deepseek-v4-flash'`)
  - `cli_options` — Hash of options merged into the Cline CLI invocation (e.g. `plan: true`)
  - `configure_global` — Proc given the Cline global settings to tweak

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

### `XAeonAgents::Config`

Singleton module holding all X-Aeon Agents configuration (secrets, data directory, default Cline CLI arguments, debug flag). All methods listed below are part of the `Public API` YARD group.

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
- `config_paths` — candidate paths of the optional `.x_aeon_agents.rb` config file. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#config_paths-class_method)
- `logger` — the shared logger instance. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/Config#logger-class_method)

### `XAeonAgents::GenHelpers`

DSL mixed into ERB skill templates, used to generate skill files (metadata, goals, rules, todo lists).

**Usecase** — declare a skill's frontmatter inside an ERB template:

```erb
<%= skill(description: 'Implement a GitHub issue', dependencies: ['analyzing-github-issue']) %>
```

More details: [RubyDoc — XAeonAgents::GenHelpers](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers)

Public methods:
- `skill(description:, dependencies:, plan:, metadata:)` — define skill metadata / YAML frontmatter. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#skill-instance_method)
- `goal(goal_desc = nil)` — define or get the skill goal. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#goal-instance_method)
- `goal_sentence` — the skill goal as a sentence. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#goal_sentence-instance_method)
- `announce` — the prompt announcing the agent is working on the skill. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#announce-instance_method)
- `tmp_path` — default temporary folder for agents. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#tmp_path-instance_method)
- `rule(title, ...)` — generate a documented rule block. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#rule-instance_method)
- `ordered_todo_list(&erb_block)` — generate a numbered todo list section. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#ordered_todo_list-instance_method)
- `when_to_use(&erb_block)` — generate the “When to use it” section. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#when_to_use-instance_method)
- `name` — the skill name being generated. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#name-instance_method)
- `self.config(skill_name)` — read a skill's `.skill_config.yml`. [doc](https://www.rubydoc.info/gems/x-aeon_agents/XAeonAgents/GenHelpers#config-class_method)

### `XAeonAgents::Logger`

The shared status-aware logger used by all X-Aeon Agents components (accessible through `XAeonAgents::Config.logger`). It inherits from the standard Ruby `Logger`; the methods below are part of the public API, on top of the standard `::Logger` interface.

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

## Documentation

- **GitHub repository** — main project page with source code, issues and CI: [github.com/Muriel-Salvan/x\_aeon\_agents](https://github.com/Muriel-Salvan/x_aeon_agents)
- **Project README** — overview, CLI usage and skill-authoring guidelines: [github.com/Muriel-Salvan/x\_aeon\_agents/blob/main/README.md](https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/README.md)
- **RubyDoc.info** — full API reference generated from the source (YARD): [rubydoc.info/gems/x\_aeon\_agents](https://www.rubydoc.info/gems/x_aeon_agents)
- **RubyGems** — published gem page and release history: [rubygems.org/gems/x\_aeon\_agents](https://rubygems.org/gems/x_aeon_agents)

### Library public API

The documented public methods (browseable on RubyDoc.info):

- `XAeonAgents` module:
  - `agent_name` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents#agent_name-class_method)
  - `agent_signature` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents#agent_signature-class_method)
  - `VERSION` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents#VERSION-constant)
- `XAeonAgents::GenHelpers` — DSL helpers for generating skill content from ERB templates:
  - `skill` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#skill-instance_method)
  - `goal` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#goal-instance_method)
  - `goal_sentence` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#goal_sentence-instance_method)
  - `announce` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#announce-instance_method)
  - `tmp_path` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#tmp_path-instance_method)
  - `rule` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#rule-instance_method)
  - `ordered_todo_list` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#ordered_todo_list-instance_method)
  - `when_to_use` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#when_to_use-instance_method)
  - `name` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#name-instance_method)
  - `config` (class method) — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers#config-class_method)
- `XAeonAgents::GenHelpers::ErbEvaluator` — helper class to evaluate ERB skill templates:
  - `new` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers/ErbEvaluator#new-instance_method)
  - `result` — [doc](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/GenHelpers/ErbEvaluator#result-instance_method)

## How it works

`x_aeon_agents` is a 💎 **Ruby gem** organized into three layers: a **CLI**, a set of **orchestrating agents**, and a shared **configuration / helper** core that glues them together.

### Entry point 🚪

- The [`xaa`](https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/bin/xaa) executable boots [Zeitwerk](https://github.com/fxn/zeitwerk) auto-loading and calls `XAeonAgents::Cli.start(ARGV)`.
- The CLI ([`lib/x_aeon_agents/cli.rb`](https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/lib/x_aeon_agents/cli.rb)) is a [Thor](https://github.com/rails/thor) application: every sub-command (`commit`, `create-pr`, `review-comments`, `implement-issue`, `generate-readme`…) maps **1:1** to an agent class.
- On startup it loads the optional `.x_aeon_agents.rb` config (home directory, then project directory) so project-level settings override global ones, and explicit CLI flags (`--session-id`, `--debug`) override both.

### Agents as composable workflows 🧩

Each capability is implemented by an `Agents::*Agent` class built on `composable_agents`:

- `ComposableAgents::Agent` — pure orchestrators that run shell commands and coordinate child agents.
- `ComposableAgents::AiAgents::Agent` / `ComposableAgents::Cline::Agent` — LLM-driven agents that execute prompts against an AI backend.

Every agent is enriched by the [`AgentDefaults`](https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/lib/x_aeon_agents/agent_defaults.rb) mixin, which:

- injects `new_agent`, `task`, `step` and `step_agent` to build multi-step pipelines;
- auto-configures the frameworks (`setup_composable_agents`, `setup_ai_agents`, `setup_cline`) and injects per-class defaults (overridable with the `configure_agent` config DSL);
- enforces **input/output artifact contracts** and adds **resume** support (via the `ArtifactContract` + `Resumable` mixins);
- gives each agent a per-session directory under `Config.data_dir/sessions/<id>`.

### Orchestration 🔗

A top-level agent decomposes its job into **steps**, delegating each one to child agents. State flows through a shared `@artifacts` hash referenced via `artifact_ref` — e.g. `DeveloperAgent` chains `PlannerAgent` ➜ `CoderAgent` ➜ `TesterAgent` ➜ `CommitterAgent` / `DocumenterAgent` ➜ `PullRequestCreatorAgent`:

```mermaid
flowchart TD
  CLI[XAeonAgents::Cli / xaa] -->|instantiates + run| A[Top-level Agent]
  A -->|task / step_agent| P[PlannerAgent]
  A -->|task / step_agent| C[CoderAgent]
  A -->|task / step_agent| T[TesterAgent]
  A -->|task / step_agent| K[CommitterAgent]
  A -->|task / step_agent| D[DocumenterAgent]
  A -->|task / step_agent| PR[PullRequestCreatorAgent]
  C -.->|artifacts hash| T
  T -.->|artifacts hash| K
  subgraph LLM[AI backends]
    C --> Prov[Cline / OpenRouter provider]
    T --> Prov
  end
  K --> Git[(Git + GitHub via Octokit)]
```

### Configuration & providers 🔐

- [`XAeonAgents::Config`](https://www.rubydoc.info/gems/x_aeon_agents/XAeonAgents/Config) is a singleton holding secrets (`cline_api_key`, `openrouter_api_key`, `github_token`), the data directory and the debug flag. Secrets are resolved with the precedence *explicit setter ➜ `ENV` variable ➜ lazy Proc from the config DSL*.
- LLM calls flow through [`Providers::Cline`](https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/lib/x_aeon_agents/providers/cline.rb), an OpenAI-compatible [RubyLLM](https://github.com/crmne/ruby_llm) provider targeting the Cline API (`https://api.cline.bot/api/v1`) and parsing responses including thinking blocks, tool calls and token usage.

### Skills & ERB templating 📚

- Reusable agent instructions live as Markdown **skills** in `skills/`, some generated from ERB templates in `skills.src/`.
- `xaa generate-skills` evaluates those templates with the [`GenHelpers`](https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/lib/x_aeon_agents/gen_helpers.rb) DSL (via `GenHelpers::ErbEvaluator`) to emit YAML front-matter, goals, rules and checklists.
- `xaa install-skills` reads the `.skills` manifest and installs each skill together with its recursively-resolved dependencies.

### Helpers 🛠️

[`XAeonAgents::Helpers`](https://github.com/Muriel-Salvan/x_aeon_agents/blob/main/lib/x_aeon_agents/helpers.rb) centralizes the plumbing used by every agent:

- real-time command execution (`run_cmd`) with expected exit status;
- cached Git / GitHub (Octokit) clients and diff extraction (`git_diff_cached`, `artifact_files_diffs`);
- interactive content review (opens a temp file via Launchy for human approval).

## Development

This section explains how to set up a local environment to develop **x_aeon_agents**, run its test suite, lint the code, build the gem and regenerate the packaged skills.

### Prerequisites

- **Ruby** `>= 3.1` (the CI pipeline runs on Ruby `3.4`) and a matching **Bundler**.
- **Git** command-line client.
- *(Maintainer only)* **Node.js** and **npm**, required for `skillkit` and `semantic-release` used during packaging and release.

### Clone and install dependencies

```bash
git clone https://github.com/Muriel-Salvan/x_aeon_agents.git
cd x_aeon_agents
bundle install
```

`bundle install` installs the runtime dependencies declared in `x_aeon_agents.gemspec` plus the development dependencies from the `Gemfile` (`rspec`, `rubocop`, `rubocop-rspec`, `rubocop-yard`, `simplecov`, `simplecov-cobertura`, `sem_ver_components`).

> [!NOTE]
> `Gemfile.lock` is intentionally git-ignored: this is a library, not an application.

### Project layout

```text
lib/                    # Library source, auto-loaded with Zeitwerk (entry: lib/x_aeon_agents.rb)
  x_aeon_agents/
    cli.rb              # The `xaa` Thor CLI definition
    config.rb           # Global configuration
    agents/             # AI agents (commit, PR, README generation, ...)
    providers/          # LLM provider integrations
    gen_helpers.rb      # ERB skill template helpers
    version.rb          # Gem version (bumped automatically on release)
bin/
  xaa                   # CLI executable
skills.src/             # ERB skill templates (source of truth)
skills/                 # Generated skills (produced from skills.src)
spec/                   # RSpec test suite
  spec_helper.rb        # Global RSpec / SimpleCov configuration
  scenarios/            # End-to-end scenario specs
  x_aeon_agents_test/   # Test helpers (loaded via Zeitwerk)
.github/workflows/      # CI (continuous_integration.yml)
```

### Running the test suite

Tests use **RSpec 3** with **SimpleCov** coverage (minimum 98%).

```bash
# Run the whole suite, exactly like the CI does
bundle exec rspec --format documentation

# Run a single file or directory
bundle exec rspec spec/scenarios/code_quality_spec.rb

# Enable verbose test logging
TEST_DEBUG=1 bundle exec rspec
```

The coverage report is written to `coverage/` (HTML plus Cobertura format for Codecov). Each example runs with a cleaned, temporary `.x_aeon_agents_test/` data directory (git-ignored), and the application configuration is populated with dummy API keys by `spec_helper.rb`.

### Linting

Code style is enforced with **RuboCop** (`rubocop`, `rubocop-rspec`, `rubocop-yard`), configured through `.rubocop.yml`.

```bash
# Check style
bundle exec rubocop

# Check and auto-correct
bundle exec rubocop -A
```

### Building skills from templates

Some skills are authored as ERB templates under `skills.src/`. Generate the final `skills/` files with:

```bash
bundle exec ruby bin/xaa generate-skills
```

This finds every `.erb` file in `skills.src/`, evaluates it with the `XAeonAgents::GenHelpers` DSL and writes the resulting files (minus the `.erb` extension). Always regenerate skills before committing so the committed `skills/` directory stays in sync with its sources.

### Common development tasks

Run the CLI locally without installing the gem:

```bash
bundle exec ruby bin/xaa --help
bundle exec ruby bin/xaa <command> [options]
```

Common commands while developing: `xaa start-task --branch feature/my-change` opens a git worktree for a feature branch, `xaa generate-readme` regenerates this README, and `xaa commit` / `xaa create-pr` drive the commit and Pull Request workflow.

Build the gem package locally:

```bash
gem build x_aeon_agents.gemspec
```

This produces a `x_aeon_agents-<version>.gem` file. Note that `x_aeon_agents.gemspec` only packages `lib/**/*` and top-level `*.md`/`*.txt` files; the `skills/` directory is committed to the repository separately (regenerate it first) and is not bundled inside the gem.

Generate the API documentation with **YARD** (output in `doc/`, git-ignored):

```bash
bundle exec yard
```

### Packaging and release

Releases are automated through the `package` job of GitHub Actions using `semantic-release` and `semantic-release-rubygem`:

1. Skills are regenerated (`bundle exec ruby bin/xaa generate-skills`) and staged.
2. `semantic-release` computes the next version from conventional commits, updates `lib/x_aeon_agents/version.rb` and `CHANGELOG.md`, and creates a Git tag plus a GitHub release.
3. The gem is built and pushed to RubyGems.

Contributors do not need to run these release steps locally — just make sure tests pass with `bundle exec rspec` and skills are regenerated with `bundle exec ruby bin/xaa generate-skills` before sharing your changes.

## Contributing

Contributions to **x_aeon_agents** are welcome! 🌱 This 💎 Ruby gem lives on [GitHub](https://github.com/Muriel-Salvan/x_aeon_agents) and is released automatically via `semantic-release`, so a clean, linear history and passing CI keep the project healthy.

### 🐛 Reporting issues

- Open a new issue on the [issue tracker](https://github.com/Muriel-Salvan/x_aeon_agents/issues) and describe the *expected* vs *actual* behavior, your Ruby version, and clear steps to reproduce.
- For a bug in a specific skill, mention the skill name (e.g. `addressing-pull-request-comments`) and the command you ran.

### 🍴 Forking & branching

- 📌 *Fork* the repo and add upstream as a remote named `github`: `git remote add github https://github.com/Muriel-Salvan/x_aeon_agents.git`.
- Create a *feature branch* from `main`; the project favors git worktrees, so you can run `xaa start-task --branch feature/my-change`.
- Keep your branch current by *rebasing* on `github/main` (`git fetch --all && git rebase github/main`) — never merge.

### 🧪 Running the tests

To run the suite locally, first install the test dependencies with `bundle install` (the `Gemfile` pulls in RSpec 3, RuboCop, SimpleCov and its Cobertura formatter), then launch the full suite exactly like CI with `bundle exec rspec --format documentation`, or scope it to a single file such as `bundle exec rspec spec/scenarios/code_quality_spec.rb`; each example runs against a temporary, auto-cleaned `.x_aeon_agents_test/` directory with dummy API keys injected by `spec/spec_helper.rb`, and SimpleCov enforces a *minimum 97% coverage* before the run is considered green.

```bash
# Install test dependencies
bundle install

# Run the whole suite, exactly like the CI does
bundle exec rspec --format documentation

# Run a single file or directory
bundle exec rspec spec/scenarios/code_quality_spec.rb

# Enable verbose test logging
TEST_DEBUG=1 bundle exec rspec
```

### 🔀 Opening a Pull Request

- Push your branch to your fork and open a PR *against* `main` on the upstream repo.
- Describe *what* changed and *why*, and link the related issue when relevant.
- Rebase on the latest `github/main` and push with `git push github --force-with-lease` if you rebased.

### 🤖 CI & coverage

- Every push triggers the [continuous integration workflow](https://github.com/Muriel-Salvan/x_aeon_agents/actions/workflows/continuous_integration.yml), which runs on Ruby `3.4`, installs `skillkit`, executes the tests and uploads coverage to Codecov.
- The `package` job regenerates skills (`bundle exec ruby bin/xaa generate-skills`) and runs `npx semantic-release` — you don't need to run these locally, but your changes must not break them.

### 🧹 Code style

- Lint with `bundle exec rubocop` (config in `.rubocop.yml`, using `rubocop`, `rubocop-rspec` and `rubocop-yard`); auto-fix with `bundle exec rubocop -A`.
- If you edit a skill written as an ERB template under `skills.src/`, *always* regenerate the committed `skills/` files with `bundle exec ruby bin/xaa generate-skills` before committing.

### ✅ Before you submit

- 🟢 All RSpec examples pass and coverage stays ≥ 97%.
- 🪄 `rubocop` reports no offenses.
- 📝 Generated skills are in sync (`skills/` matches `skills.src/`).
- 📜 Keep the [BSD-3-Clause](LICENSE) license and stay kind & respectful in all interactions. 💛

## License

This project is distributed under a modified BSD-3-Clause License. See the [LICENSE](LICENSE) file for the full license terms and copyright information.

## Ways skills are written

* Follow guidelines from the following sources:
  * [agentskills.io](https://agentskills.io/specification)
  * [Claude code best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
* Help agents follow those skills and their steps by using the following guidelines:
  * About skill name and YAML frontmatter:
    * Always name skills using `<verb>[-<object>-[<context>]]`.
    * Use gerund in the skill name.
    * Use third person in the skill description.
    * Always add a `Use when ...` part of the skill description.
  * About skill content:
    * Use Markdown for the skill's content.
    * Use imperative verbs (ex: `Read the README file to know about the CLI usage`).
    * Separate ordered steps in the skill's content using Markdown's headers (ex: `## 5. Perform data analysis`), and give details of this step using bullet points.
    * Don't mix several commands in 1 step. Split steps if several commands are involved.
    * Use `{variable_name}` to identify placeholders.
    * Be clear and consistent about commands: always use backticks to identify a command, and use a prefix for the command type. Here are the prefixes in use:
      * `cli: `: Used for command-line tools. Ex: ``Use `cli: ls -la` to list all the files``.
      * `agent: `: Used for agent commands. Ex: ``Use `agent: ask_followup_question` to ask the USER about the intent``.
      * `skill: `: Used for skills. Ex: ``Use `skill: creating-pull-request` to create the PR for {branch}``.
    * Don't use capital wordings as it adds emotional noise and is different from non-capitalized tokens used during LLMs training.
    * Use some wording in a consistent way. Those words are inspired by https://github.com/rohitg00/skillkit/blob/39b94534ec1c3698c0dec3a005744dafa99e63e9/packages/core/src/quality/index.ts
      * `User` represents the developer asking the agent to perform a task.
      * `Always` is used to emphasize that a specific step is mandatory (ex.: ``Always use `cli: gh` to gather issue information``).
      * `Never` is used to emphasize that a specific step should never be done (ex.: ``Never use `cli: gh` to create a PR``).
      * `If` ... `then` ... `else` are used to clearly identify some branching decisions.
      * `Plan` and `Act` modes refer to precisely the 2 ways of executing skills by the agents.
  * About skill semantics:
    * A skill is better followed when it consists only in a sequence of easily identified steps (like a workflow). Don't use vague guidelines in a skill.
    * When another skill is performing a sub-task of your skill, reference it explicitely, like ``Use `skill: skill_name` to perform this action`` instead of `Perform this action`. Don't rely on the model understanding that `skill_name` was the right skill to perform the action.
    * Always ask the agent to inform the user about executing the skill.
    * Any step that can be coded and automated with a tool should be implemented in a tool. Never rely on the guarantee that models will follow steps, unless they are implemented in a tool.

## General principles

Those principles allow for a safe agent interaction, while keeping its agility.

* The user sets the branch for the agent, in a worktree.
* Agents should never switch branches.
* Agents automatically push their changes to the github remote, and create a Pull Request for their branch.
* Agents can rebase their branch.

## Generating skills from ERB templates

Some skills are written as ERB templates (files ending with `.erb`) to allow dynamic content generation. To generate the final skill files from these templates, run the following executable:

```bash
bundle exec ruby bin/xaa generate-skills
```

This will:
- Find all `.erb` files in the `skills/` directory
- Process them using the ERB engine (with `XAeonAgents::GenHelpers` available)
- Generate the corresponding output files (removing the `.erb` extension)

The following helper methods are available in ERB templates:
- `XAeonAgents::GenHelpers.init_skill_checklist` - Returns the "Create Execution Checklist (MANDATORY)" section
- `XAeonAgents::GenHelpers.validate_skill_checklist` - Returns the "Final Verification (MANDATORY)" section
