# 00 - Initial AI assistant session: copilot instructions & template

Date: 2025-11-08

Author: contributor session (interactive edit)

Role: Developer

Related docs: `docs/agents-summaries/XX-task.md` (template), `.github/copilot-instructions.md`

## Summary
Created or updated repository guidance for AI coding agents and added a
template for `docs/agents-summaries/XX-task.md`. This is the first example
summary demonstrating the docs-first workflow required by the project.

## Motivation
Make it easy for future contributors (human or automated) to follow the
Docs First process and to produce short, discoverable post-task summaries.

## Files changed
- `.github/copilot-instructions.md` — new file added and updated to include "Your role" and "Docs First" sections.
- `docs/agents-summaries/XX-task.md` — new template for agent summaries.

## Commands run (for verification / reproduce)
No shell commands were required; the changes were made directly in the workspace.

## Verification
Files created in the repository root under `./.github/` and `./docs/agents-summaries/`.
Manual review shows the template and the updated copilot instructions exist.

## Side effects / Notes
- The project now enforces (in documentation) a docs-first workflow. Contributors
  should create numbered docs in `docs/` and add a short `docs/agents-summaries/` entry
  after completing work.

## Next steps
1. Review the new `.github/copilot-instructions.md` and confirm wording.
2. If desired, I can open a PR with these files or adapt the template format.
3. Optionally add a CI check (linting or existence check) to ensure every merged PR
   includes a `docs/agents-summaries/` entry when it modifies design/architecture.
