# Workflow design: why engineer your agents?

Most discussions about AI-assisted development ask a single question: *which model should we use?* That
question matters, but it hides a second one: **how much of software development should depend on a model's
judgment at all?**

A large part of software engineering is not intelligence. It is process: compilers, linters, tests, code
review, CI, architectural rules. We do not ask human developers to remember every rule and personally
guarantee every quality requirement — we build processes that enforce them. Agents deserve the same
treatment.

`x_aeon_agents` exists to make that process explicit, reusable and deterministic.

## Conventional approach vs. engineered approach

| | Conventional agent setup | Engineered workflow |
| --- | --- | --- |
| **Shape** | One powerful agent per task | An explicit process with specialized responsibilities |
| **Who decides the process** | The model, at every run | The workflow author, once |
| **Context** | One growing conversation | Named artifacts with contracts |
| **Quality** | Whatever the model remembers to do | Steps in the process: planning, tests, review, documentation |
| **Reproducibility** | Varies with the model, the prompt and the day | Same steps, same contracts, same gates |
| **Cost driver** | Model capability required for the whole task | Model capability required for each step |
| **Failure mode** | Silent: plausible output, missing process | Explicit: a failing gate or a missing artifact |

The engineered side is not "more agents". It is **a written process executed by agents**.

## The three principles

### 1. Separation of responsibilities

Each agent has one responsibility and a limited remit: planning, implementing, testing, reviewing,
documenting, delivering. Narrow responsibilities make instructions shorter, prompts more reliable, and
failures attributable. A monolithic agent that must remember to test, document, commit and open a PR will
eventually forget one of them; a specialized agent that only tests has very little to forget.

### 2. Explicit interfaces

Agents exchange **named artifacts with declared contracts** (a plan, a diff, a test report, a commit
message) instead of sharing an ever-growing conversation. Artifacts are inspectable, resumable, diffable,
and can be reviewed by a human. They also bound the context each step receives: a downstream agent reads a
contract, not the whole transcript.

### 3. Engineering quality into the workflow

Testing, validation, review and documentation are **steps of the process**, not suggestions left to the
model's diligence. If a step can be enforced by a tool, it is enforced by a tool — a shell command with an
expected exit status, a contract that fails on a missing artifact, a gate that stops the workflow.

## What this does not mean

- **It is not about maximizing the number of agents.** Splitting work has a cost (context handoffs,
  orchestration, tokens). Add an agent when it buys isolation, a contract, or a quality gate — not for its
  own sake.
- **It is not an autonomous coding agent.** `x_aeon_agents` does not try to be a general-purpose assistant
  that decides what to do with your repository. It provides workflows with defined scope, and you decide
  when to run them.
- **It does not dismiss better models.** Better models help, and combining them with a good workflow helps
  more. The claim is narrower: *for a given model*, engineering the surrounding system improves the
  outcome.

## Anatomy of a workflow

A workflow is made of five things:

1. **A top-level agent** — an orchestrator with no LLM of its own. It decomposes the job, decides which
   steps run, and handles retries. (`ComposableAgents::Agent`)
2. **Steps** — the ordered units of work. Each step has an intent, an input contract and an output contract.
3. **Child agents** — the specialists that execute steps. They are either orchestrators (shell work) or
   LLM agents (reasoning and editing).
4. **Quality gates** — commands that must succeed (tests, linters, builds) and contracts that must be
   satisfied before the workflow continues.
5. **Delivery** — the last step is deliberately boring: commit with a generated message, push, open the PR.

The developer-facing entry point is a CLI command that instantiates the top-level agent. Nothing else about
the workflow is coupled to Thor.

## Ownership and safety rules

These rules are part of the design, not incidental conventions:

- **The user owns the branch.** Work happens on the branch that is already checked out, in its own git
  worktree; agents never switch branches.
- **Agents push to the `github` remote and open Pull Requests** rather than leaving local state behind.
- **Agents may rebase** their own branch, never merge the base into it.
- **Destructive ambiguity is resolved by stopping**, not by guessing: a missing contract or a failing gate
  surfaces as an error.
- **Runs are bounded.** Cline agents get a timeout and a retry budget by default, and the tools they do not
  need are disabled.

## Designing a new workflow

Use this checklist before writing code:

1. **Name the outcome**, not the activities: "implement an issue and open a PR", "address review comments",
   "generate a commit message".
2. **List the responsibilities** involved. Each one becomes either a step or a child agent — if two
   responsibilities never need separate contracts or gates, keep them in one agent.
3. **Define the artifacts** crossing each boundary: name, type, and what makes them valid. If you cannot
   name the artifact, the boundary is probably wrong.
4. **Place the gates**: what must be verified before the next step is allowed to run? Prefer a command over
   an instruction.
5. **Decide the failure policy**: retry, escalate to a repair step, or stop. Workflows that retry forever
   are worse than workflows that fail loudly.
6. **Check resumability**: if the process stops, can it resume from a session id instead of re-running
   everything?
7. **Assign models per role** in the configuration: the planner and the reviewer may deserve a stronger
   model than the committer.
8. **Write the spec** that proves the happy path and the interesting failure.

## Adding a workflow to the codebase

1. Create the agent(s) under `lib/x_aeon_agents/agents/`, `prepend AgentDefaults`, and declare the input and
   output artifact contracts.
2. Implement `run`, composing steps with `new_agent` / `task` / `step_agent`. Keep the orchestrator free of
   LLM calls.
3. Add the CLI command in `lib/x_aeon_agents/cli.rb`: one `desc`, one `long_desc` with examples, one agent
   instantiation.
4. Add a skill under `skills.src/` if the workflow is also useful to a coding agent directly (many are).
5. Add a scenario spec under `spec/scenarios/` covering the happy path and the failure modes, then
   regenerate the skills.
6. Document the workflow in the README table and, if it deserves it, with a page in `docs/`.

## Anti-patterns

- **The omniscient prompt** — one agent told to plan, code, test, document and commit. It works until it
  doesn't, and then nothing tells you which part failed.
- **Conversation as an interface** — passing state by accumulating messages. It scales badly and makes
  runs irreproducible.
- **Optional quality checks** — "you should also run the tests" is not a gate.
- **Unbounded retries** — a loop without a budget hides a design problem.
- **Agents for everything** — orchestration is cheaper in Ruby than in tokens.
- **Model maximalism** — using a frontier model for a step a cheap model performs reliably is a cost bug.

## Further reading

- [Architecture](architecture.md) — how agents, artifacts and providers are implemented.
- [Benchmarks](benchmarks.md) — how the approach is evaluated.
- The article that states the case:
  [Stop Scaling Models. Start Engineering Your AI Agents.](https://blog.x-aeon.com/2026/11/23/stop-scaling-models-start-engineering-your-ai-agents/)

