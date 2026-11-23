# Contributing to x_aeon_agents

Thanks for your interest! `x_aeon_agents` is not only a Ruby gem: it is an attempt at turning
software-engineering practices into explicit, reusable workflows for AI coding agents. That means
there are many ways to contribute, and most of them do not require being a Ruby expert.

## Ways to contribute

| Contribution | What it looks like | Start here |
| --- | --- | --- |
| **Create a workflow** | Design a new software-engineering process (responsibilities, steps, artifacts) and expose it as a CLI command | [docs/workflow-design.md](docs/workflow-design.md) |
| **Improve an existing workflow** | Make an agent more reliable: better constraints, better artifacts, better quality gates | `lib/x_aeon_agents/agents/` |
| **Write or improve a skill** | Skills are the instructions agents follow. They are Markdown, generated from ERB templates | [docs/skill-authoring.md](docs/skill-authoring.md) |
| **Expand the benchmarks** | Add scenarios that evaluate engineered workflows against conventional agent setups | [docs/benchmarks.md](docs/benchmarks.md) and [agentic-dev-bench](https://github.com/Muriel-Salvan/agentic-dev-bench) |
| **Integrate models and tools** | Add a provider, or wire a new CLI/tool into the agents' tool constraints | `lib/x_aeon_agents/providers/` |
| **Improve documentation** | Fix inaccuracies, clarify a workflow, write a tutorial or a field report | This file, `docs/`, issues |
| **Report a bug** | Expected vs actual behavior, Ruby version, reproduction steps | [Issue tracker](https://github.com/Muriel-Salvan/x_aeon_agents/issues) |
| **Contribute code** | Fix bugs, refactor, add specs | The rest of this file |

If you are unsure where your idea fits, open an issue and ask. Design discussions are welcome
*before* code: workflows are architecture, and a written design is often more valuable than a patch.

## Development environment

### Prerequisites

- **Ruby** `>= 3.3` (CI runs `3.4`) with a matching Bundler.
- **Git** command-line client.
- **Node.js** and **npm** are only needed for tooling: `skillkit` (installs skills in CI) and
  `semantic-release` (release job). They are *not* needed to run the test suite.

### Setup

```bash
git clone https://github.com/Muriel-Salvan/x_aeon_agents.git
cd x_aeon_agents
bundle install
```

`bundle install` installs the runtime dependencies declared in `x_aeon_agents.gemspec` plus the
development dependencies from the `Gemfile` (`rspec`, `rubocop`, `rubocop-rspec`, `rubocop-yard`,
`simplecov`, `simplecov-cobertura`, `sem_ver_components`).

> [!NOTE]
> `Gemfile.lock` is intentionally git-ignored: this is a library, not an application.

## Tests

Tests use **RSpec 3** with **SimpleCov** coverage, and CI runs them exactly like this:

```bash
bundle exec rspec --format documentation
```

Useful variations:

```bash
# Run a single file or directory
bundle exec rspec spec/scenarios/code_quality_spec.rb

# Enable verbose test logging
TEST_DEBUG=1 bundle exec rspec
```

- **Minimum coverage is 99%**, enforced by `spec/spec_helper.rb`. A run below that threshold is a
  failure, even if every example passes. This is the only place where the coverage threshold should be
  stated — do not duplicate the number in the README, it drifts.
- Each example runs against a cleaned, temporary `.x_aeon_agents_test/` data directory (git-ignored),
  and `spec_helper.rb` injects dummy API keys: **the suite needs no credentials and no network**.
- `spec/scenarios/` holds end-to-end scenarios, one behavior per file. `spec/x_aeon_agents_test/` holds
  the test helpers and stubs (loaded with Zeitwerk).

### Never call a real LLM in a test

Agent behavior is stubbed through the helpers in `spec/x_aeon_agents_test/helpers/`:

- `stub_agent_run` prepends `XAeonAgentsTest::Stubs::PromptAgentsStubAgent` on the agent base classes, so
  every AI agent returns mocked artifacts instead of calling a provider.
- `stub_commands`, `mock_git_remotes`, `with_workspace` and friends isolate shell, Git and filesystem effects.
- `spec/scenarios/x_aeon_agents/agents/readme_generator_agent_*_spec.rb` are good examples of asserting
  generated documents end to end.

When you add behavior, add the scenario file that proves it. A workflow change without a spec is an
unverified prompt change.

## Lint and API documentation

```bash
# Check style
bundle exec rubocop

# Check and auto-correct
bundle exec rubocop -A

# Generate the API documentation (output in doc/, git-ignored)
bundle exec yard
```

- Style is enforced with `rubocop`, `rubocop-rspec` and `rubocop-yard` (`.rubocop.yml`).
- YARD is a hard gate, not a nicety: `spec/scenarios/documentation_spec.rb` runs
  `yard doc --fail-on-warning` and `yard stats --list-undoc --fail-on-warning`, and requires
  **100% documented** code. Every public class, module, method, attribute and constant needs a YARD
  comment, with `@param`/`@return` tags where applicable.
- Public entry points belong to YARD's `@!group Public API`.

## Skills

Skills are the instructions agents follow, and they ship with the gem.

- `skills.src/` is the **source of truth**; `skills/` is **generated output** and must stay in sync.
- After editing a template, regenerate before committing:

```bash
bundle exec ruby bin/xaa generate-skills
```

- `xaa generate-skills --output-dir custom_dir` changes the destination, and
  `--skill name1 --skill name2` restricts generation to specific skills.
- `spec/scenarios/skills/quality_spec.rb` validates the generated skills, and CI installs them with
  `skillkit`. Authoring rules are documented in [docs/skill-authoring.md](docs/skill-authoring.md).

## Documentation layout and rules

- **`README.md` is hand-maintained.** It is the landing page: proposition, philosophy, benchmarks,
  quick start. It is *not* generated anymore, so **do not run `xaa generate-readme` in this
  repository** — it would rewrite the file with LLM-generated sections and discard the editorial work.
- **`docs/` holds the details**: [architecture](docs/architecture.md),
  [configuration](docs/configuration.md), [workflow design](docs/workflow-design.md),
  [skill authoring](docs/skill-authoring.md) and [benchmarks](docs/benchmarks.md).
- **Rule of division**: the README summarises and links; `docs/` explains. When a detail changes, update
  `docs/` first, then adjust the README summary if the reader's understanding changes.
- **The README table of contents is maintained by hand.** Every `##` and `###` heading must appear in it,
  in document order. If you have Node installed, `npx doctoc README.md` regenerates it in the
  GitHub anchor style already in use.
- The public API reference is generated by YARD from the source and published on RubyDoc.info; do not
  duplicate it in the README.

## Commits and Pull Requests

Releases are fully automated, and the version number is derived from the commit log. Commit messages
are therefore part of the public contract of the project.

- Use **Conventional Commits**: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`, `ci:`,
  optionally scoped — `feat(agents): bound agent runs with default timeout`, `docs(readme): restructure
  the landing page`.
- One logical change per commit; do not mix formatting and behavior.
- Open Pull Requests **against `main`**, describe *what* changed and *why*, and link the related issue.
- After a rebase, push with `git push github --force-with-lease`.
- Keep the branch linear: no merge commits between your branch and `main`.

### Release pipeline (maintainers only)

The `package` job of the GitHub workflow runs after a green test job and:

1. regenerates `skills/` from `skills.src/` and stages it;
2. lets `semantic-release` compute the next version from conventional commits, update
   `lib/x_aeon_agents/version.rb` and `CHANGELOG.md`, tag the release and publish the GitHub release;
3. builds the gem and pushes it to RubyGems.

Contributors never run these steps locally — just make sure the gates below pass.

## Before you submit

- [ ] `bundle exec rspec --format documentation` is green, and coverage is **≥ 99%**.
- [ ] `bundle exec rubocop` reports no offenses.
- [ ] `bundle exec yard stats --list-undoc --fail-on-warning` reports 100% documented code.
- [ ] `skills/` is regenerated if `skills.src/` changed.
- [ ] `docs/` and/or the README are updated when user-facing behavior changed.
- [ ] The branch is rebased on `github/main` and contains no merge commits.
- [ ] Commit messages are conventional.

If a gate cannot be satisfied, say so explicitly in the Pull Request instead of leaving it silent.

## Code of conduct

Be kind, be precise, assume good faith. Technical disagreement is welcome; personal attacks are not.
Discussions happen in issues and Pull Requests, and the same rules apply to humans and to agents acting
on your behalf.

## License

By contributing, you agree that your contributions are distributed under the
[BSD-3-Clause license](LICENSE) that covers this project.

