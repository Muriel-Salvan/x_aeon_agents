# Skill authoring

Skills are the instructions an agent follows to perform one well-defined activity. They are the cheapest
and highest-leverage way to improve agent behavior: no Ruby, no new CLI command, just a precise process in
Markdown.

- [What a skill is](#what-a-skill-is)
- [Lifecycle: sources, generated files, installation](#lifecycle-sources-generated-files-installation)
- [Naming and frontmatter](#naming-and-frontmatter)
- [Content rules](#content-rules)
- [Semantics](#semantics)
- [ERB templating](#erb-templating)
- [`GenHelpers` reference](#genhelpers-reference)
- [Per-skill configuration](#per-skill-configuration)
- [Quality gates](#quality-gates)

## What a skill is

A skill is a directory containing a `SKILL.md` file (plus optional scripts and references):

```text
skills/<skill-name>/
  SKILL.md              instruction file with YAML frontmatter
  scripts/              optional executables the skill tells the agent to run
  references/           optional deeper documentation loaded only when needed
```

The frontmatter declares the skill's `name` and `description`; the body declares the process. Agents are
configured with the skills they should follow through `configure_agent(... skills: [...])` — see
[configuration](configuration.md).

## Lifecycle: sources, generated files, installation

1. **Sources live in `skills.src/<skill-name>/`.** `SKILL.md.erb` is the template; other files
   (`scripts/`, `references/`, `.skill_config.yml`) live next to it.
2. **Generate the shipped skills** with:

   ```bash
   bundle exec ruby bin/xaa generate-skills
   ```

   Every `.erb` file is evaluated with the `XAeonAgents::GenHelpers` DSL and written to `skills/` without
   the `.erb` extension; all other files are copied as-is. Options: `--output-dir DIR`, and
   `--skill name1,name2` (or repeated `--skill`) to restrict generation.
3. **Commit both**: `skills.src/` and the regenerated `skills/`. They must never diverge.
4. **Install skills into an agent** from the `.skills` manifest:

   ```bash
   bundle exec ruby bin/xaa install-skills            # cline agent, project scope
   bundle exec ruby bin/xaa install-skills --global   # user scope
   bundle exec ruby bin/xaa install-skills --agent cline
   ```

   The manifest lists sources and skill names:
   `.skills` in this repository pulls `skill-creator` from `anthropics/skills` and the project skills from
   `Muriel-Salvan/x_aeon_agents`. Dependencies declared in a skill's frontmatter are resolved recursively.
5. **Read a skill** with `skillkit read <skill-name>` (or `npx skillkit read <skill-name>`).

The generator refuses to produce garbage silently: `xaa generate-skills` exits with status 1 if
generation fails.

## Naming and frontmatter

Rules, derived from [agentskills.io](https://agentskills.io/specification) and the
[Claude Code skill best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):

- Name skills `<verb>[-<object>-[<context>]]` — for example `implementing-github-issue`,
  `addressing-pull-request-comments`, `running-cli-in-wsl-portable`.
- Use the **gerund** form in the name.
- Write the description in the **third person**, and always include a `Use when ...` part.
- If the skill applies in Plan mode, generate the frontmatter with `plan: true`: it appends
  "Use this skill also in Plan mode." to the description and sets `metadata.agent: Plan`.
- Declare inter-skill dependencies explicitly with `dependencies:` rather than hoping the model will infer
  them.

## Content rules

- Use Markdown.
- Use **imperative verbs** — `Read the README file to know about the CLI usage`, not "the README should be read".
- Separate ordered steps with headers (`### 3. Run the test suite`) and detail each step with bullet
  points. Do not mix several commands in one step: split them.
- Identify placeholders with `{variable_name}`.
- Identify commands by type, always in backticks:
  - `` `cli: ls -la` `` — command-line tools;
  - `` `agent: ask_followup_question` `` — agent tools;
  - `` `skill: creating-pull-request` `` — other skills.
- Do not use capitalized emphasis: it adds emotional noise and differs from the tokens models were trained on.
- Use the vocabulary consistently:
  - **User** — the developer who asked for the task.
  - **Always** — a mandatory step (`` Always use `cli: gh` to gather issue information ``).
  - **Never** — a forbidden action.
  - **If … then … else** — an explicit branch.
  - **Plan** and **Act** — the two modes skills are executed in.

## Semantics

A skill is followed much better when it reads as a **workflow** than when it lists vague guidelines:

- Prefer an unambiguous sequence of identifiable steps. Leave room for judgment only where judgment is
  genuinely required.
- When a sub-task is performed by another skill, reference it explicitly —
  `` Use `skill: skill_name` to perform this action `` — instead of describing it and hoping the model
  picks the right one.
- Always ask the agent to inform the user that it is running the skill (`announce` does this for you).
- **If a step can be automated with a tool, automate it.** Never rely on a model's good will to follow a
  step that a script could enforce.
- Keep a skill focused. If the instructions grow beyond one coherent activity, split it and declare the
  dependency.

## ERB templating

Templates exist to remove repetition, not to add logic: frontmatter, checklists, numbering and rule blocks
are generated so that skills stay consistent.

Example `skills.src/<skill-name>/SKILL.md.erb`:

```erb
<%= skill(description: 'Implements a GitHub issue and opens a Pull Request. Use when the user asks to implement an issue.', dependencies: ['analyzing-github-issue'], plan: true) %>

# <%= goal 'Implementing a GitHub issue' %>

<% ordered_todo_list do %>
### Analyze the issue

- Use `skill: analyzing-github-issue` to gather the requirements.

### Implement the changes

- Apply the requirements following the repository conventions.
<% end %>

## When to use it

- Use it when the user asks to implement a GitHub issue.
```

`ordered_todo_list` is the workhorse: it wraps your `###` sections into the standard skill structure, adds
step 1 ("Inform the user", using `announce`), numbers the remaining steps from 2, inserts the mandatory
execution checklist and appends the mandatory final verification section.

## `GenHelpers` reference

All methods are mixed into the ERB evaluation context:

| Method | Purpose |
| --- | --- |
| `skill(description:, dependencies: [], plan: false, metadata: {})` | Emits the YAML frontmatter (name derived from the skill directory). Must be the first call. |
| `goal(goal_desc = nil)` | Sets (or reads) the skill goal. |
| `goal_sentence` | The goal, lowercased so it reads inside a sentence. |
| `announce` | The "SKILL: I am …" instruction telling the agent to inform the user. |
| `tmp_path` | The default temporary folder agents should use (`<data_dir>/tmp`), instead of inventing one. |
| `rule(title, description: nil, type: :ruby, bad: nil, good: nil, rationale: nil)` | Emits a `### Rule: …` block with incorrect/correct examples and a rationale. |
| `ordered_todo_list { … }` | Emits the numbered, checklist-wrapped process described above. |
| `when_to_use { … }` | Emits the standard "When to use it" section. |
| `name` | The skill name being generated. |
| `GenHelpers.config(skill_name)` | Reads `skills.src/<skill_name>/.skill_config.yml` (empty hash if absent). |
| `init_skill_checklist(name)` / `validate_skill_checklist(name)` | Private helpers used by `ordered_todo_list`; callable inside templates, not part of the public API. |

The ERB itself is evaluated by `XAeonAgents::GenHelpers::ErbEvaluator` (`new(erb_file)` / `#result`), which
is also public API if you need to render a template from Ruby.

## Per-skill configuration

`skills.src/<skill-name>/.skill_config.yml` holds structured data a template can read with
`GenHelpers.config(name)` — for example lists of conventions or per-repository values. It is copied next to
the generated skill only if you place it among the files to copy; treat it as build-time input.

## Quality gates

- `spec/scenarios/skills/quality_spec.rb` validates every generated skill under `skills/`.
- CI installs skills through `skillkit`, so a broken manifest or frontmatter fails the pipeline.
- Regenerate before committing whenever `skills.src/` changes; a stale `skills/` directory is a review
  blocker.

Contributions of new skills are welcome even without Ruby knowledge: write a clear process, keep it
workflow-shaped, and the tooling will produce a valid skill from it.

