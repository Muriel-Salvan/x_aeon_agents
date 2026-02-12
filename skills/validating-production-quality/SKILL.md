---
name: validating-production-quality
description: Validates that the task is following all production-grade quality checks. Use before attempting task completion on a task or when the USER asks for it.
---

# Validating production quality

When validating production quality for the task at hand, follow those steps.

## Create Execution Checklist (MANDATORY)

- Before executing anything, create a checklist with ALL steps of this skill.
- The checklist MUST include ALL numbered steps explicitly.
- The checklist MUST be displayed to the USER at the beginning of the skill execution, and at the end of each step.
- Mark each item as completed only after execution and successful completion of the item itself.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the Execution Checklist remains open.


## 1. Inform the USER

- ALWAYS inform the user that you are running this skill, saying "SKILL: I am validating production quality".

## 2. Fix any potential regression

- ALWAYS run all test scenarios.
- ALWAYS fix all the failures that you see in the tests output.

## 3. Update documentation

- ALWAYS use `skill: updating-doc` to update the project documentation.

## 4. Commit all pending modifications

- ALWAYS use `skill: committing-changes` to commit all your changes in the current branch.

## 5. Sync the branch with its base

- ALWAYS use `skill: syncing-branch-with-base` to make sure the current branch is up-to-date with its base.
- ALWAYS check that there is no merge commit between the current branch and its base.
- If you find any merge commit, ALWAYS remove them by rebasing the branch in a linear way.

## 6. Create a Pull Request for the current branch

- ALWAYS check on the corresponding GitHub project if there is already a Pull Request created for the current branch.
- If there isn't any Pull Request for the current branch, ALWAYS use `skill: creating-pull-request` to create one.

## Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

