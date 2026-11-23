# Benchmarks

Claims about AI-assisted development are cheap. This page documents how the "engineering beats scaling"
claim is actually measured, what the first experiment showed, and how to challenge or extend it.

- [What is measured](#what-is-measured)
- [The harness](#the-harness)
- [The first experiment](#the-first-experiment)
- [Results](#results)
- [What the numbers do not prove](#what-the-numbers-do-not-prove)
- [Reproducing and contributing](#reproducing-and-contributing)

The harness lives in a separate repository so that it can be inspected, re-run and extended
independently of this gem: **[Muriel-Salvan/agentic-dev-bench](https://github.com/Muriel-Salvan/agentic-dev-bench)**
(BSD-3-Clause).

## What is measured

The question is deliberately narrow:

> For the **same model**, does an engineered workflow complete a real development task that a conventional
> agent setup fails to complete?

Each pair of scenarios runs the same task, on the same repository pinned to the same commit, with the same
model, and differs only in how the agent is orchestrated. This isolates the variable being studied: the
engineering around the model, not the model itself.

## The harness

From the benchmark repository's own description:

- A scenario **pins an existing public repository to a commit** and creates a **fresh private sandbox
  repository**.
- It creates an **issue** in the sandbox containing the requirements.
- It runs an agent through a **Harbor** adapter inside **Docker**, and records run metrics.
- `Harbor` grades the result; the overall verdict is `verifier_passed`, which is the verifier's actual
  grade and *not* the same thing as "the agent succeeded".
- After the run, analysis agents produce three reports — production code, tests and documentation — each
  seeing only the relevant part of the diff, plus a chronological run summary with the root cause of any
  failure. Analyses are written to `runs/<run_id>/` and rendered into a report.

Running the harness requires Ruby ≥ 3.2, Docker, the `harbor` CLI, a GitHub token allowed to create and
delete repositories for the configured owner, and — for the analysis agents — a Cline and an OpenRouter API
key.

## The first experiment

**Scenario:** `add-greeting` (`scenarios/add-greeting-cline-free.yml` and
`scenarios/add-greeting-xaa-free.yml`).

| | |
| --- | --- |
| **Repository** | [`Muriel-Salvan/cline-rb`](https://github.com/Muriel-Salvan/cline-rb) at tag `v1.1.3` |
| **Task (issue body)** | Add a small reusable greeting helper to the `cline-rb` configuration: a `greeting` method on `Cline::Configuration` (accessible as `Cline.config.greeting`) returning exactly `Hello, world!`; add automated tests covering it; keep the implementation small and idiomatic |
| **Verification** | `require 'cline' ; exit(Cline.config.greeting == 'Hello, world!' ? 0 : 1)` |
| **Model** | `cline:cline-free/muse-spark-1.3-contributor` — the same inexpensive free model in both configurations |
| **Baseline (system A)** | Harbor `cline-cli` agent: a conventional coding agent with tools |
| **Engineered (system B)** | Harbor `bash_script_agent.agent:BashScriptAgent` running `agents/scripts/xaa.sh`: an `x_aeon_agents` workflow |

## Results

| Configuration | Outcome | Time | Steps | Delivered | Harbor reward |
| --- | --- | --- | --- | --- | --- |
| Conventional `cline-cli` agent | **Failed** | ≈ 98 min | 208 | No implementation completed, no Pull Request | — |
| `x_aeon_agents` workflow | **Completed** | ≈ 24 min | — | Production code + tests + documentation + Pull Request, 2 commits, 8 modified files | 1.0 (maximum) |

What the baseline actually did, per the run analysis: it explored the repository, created a local feature
branch, started changing code, then got stuck repeatedly breaking and restoring the same file. It never
finished the implementation and never delivered anything through a Pull Request.

What the engineered workflow did: it planned, implemented the feature, wrote the tests, updated the
documentation, committed, pushed and opened the Pull Request — in roughly a quarter of the elapsed time.

Both runs used **exactly the same model**.

## What the numbers do not prove

- **It is one scenario.** One task on one small repository is an existence proof, not a ranking. The
  author's own conclusion: *"one benchmark scenario isn't enough to establish a universal conclusion"*.
- **Single run per configuration.** LLM runs are stochastic; repeated runs are needed before any rate can
  be quoted.
- **Prompts and scenarios evolve.** A scenario is code; results are only comparable at the same commit of
  the benchmark repository.
- **Environment matters.** Models are more reliable in the environments they were trained on; the harness
  runs Linux containers, and Windows-specific path/line-ending issues are out of scope.
- **"Reward 1.0" is a verifier result**, not a quality grade of the produced code. The analysis reports
  exist precisely to look beyond the verdict.

If you find a flaw in the methodology, open an issue in the benchmark repository. A challenge that
survives review is worth more than an unchallenged table.

## Reproducing and contributing

### Reproduce a run

1. Clone [agentic-dev-bench](https://github.com/Muriel-Salvan/agentic-dev-bench) and follow its README:
   runtime requirements, `bundle install`, environment variables (`GITHUB_TOKEN`, `GITHUB_OWNER`, and
   `CLINE_API_KEY` / `OPENROUTER_API_KEY` for the analysis agents).
2. Pick a scenario pair (`add-greeting-*`, `add-interactive-cli-*`).
3. Run it; inspect `runs/<run_id>/` for the raw logs, the metrics and the analysis report.
4. Compare the verdict (`verifier_passed`) with the analyses — the verdict says whether the feature works,
   the analyses say how it was produced.

The repository's README is authoritative for the exact commands; they are intentionally not duplicated here,
so that this page cannot drift from the harness.

### Add a scenario

A scenario is a small YAML file:

```yaml
name: Add greeting helper using x_aeon_agents free model

source:
  repository: Muriel-Salvan/cline-rb
  commit: v1.1.3

sandbox:
  owner_env: GITHUB_OWNER
  name_prefix: agentic-dev-bench

issue:
  title: Add a greeting helper
  body: |
    Add a small reusable greeting helper to the cline-rb config.
    ...

agent:
  name: bash_script_agent.agent:BashScriptAgent
  model: agents/scripts/xaa.sh

evaluation:
  ruby: "require 'cline' ; exit(Cline.config.greeting == 'Hello, world!' ? 0 : 1)"
```

Useful contributions, in decreasing order of value:

- **Paired scenarios.** For every new task, provide both the conventional configuration and the engineered
  one; a single-sided scenario cannot support a comparison.
- **Harder tasks.** More realistic feature work, refactors, multi-file changes — the current scenario is
  deliberately small.
- **Better verifiers.** An evaluation that checks tests *and* observable behavior is worth more than one
  that checks a symbol exists.
- **Cost and token capture.** Reliable cost accounting per role is still an open area.

Add the YAML file under `scenarios/`, run it at least once to confirm it is well-formed, and open a Pull
Request in the benchmark repository. Discussions about methodology are welcome in this project's
[issue tracker](https://github.com/Muriel-Salvan/x_aeon_agents/issues) too.

### Reporting results here

When a new measurement is available and reproducible, it is summarised in the README's
[benchmark section](../README.md#does-it-make-a-difference), with the details kept on this page. Numbers are
never edited for effect: if a later run contradicts an earlier one, both are reported.

