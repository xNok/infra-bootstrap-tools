<!--
Template for `docs/agents-summaries/XX-task.md` entries.
Place a new file in `docs/agents-summaries/` with the next sequential number
and follow this structure. Keep entries short and factual so newcomers can
follow the numbered trail of decisions and work items.
-->

# XX - Short title of the task (single line)

Date: YYYY-MM-DD

Author: <your name or team>

Role: Developer | Solution Architect

Related docs: `docs/01-previous.md`, `docs/02-design.md` (as applicable)

## Summary
A 2–4 sentence summary of what was done and why. Focus on the change in system state.

## Motivation
Why this change was needed. Reference issue/PR numbers when applicable.

## Files changed
List concise file paths (added/updated/removed).

`path/to/file` — short purpose

## Commands run (for verification / reproduce)
Provide the exact commands you used while testing or deploying the change.

```bash
# example
git checkout -b feature/xxx
# run stack
ibt stacks run prefect mcp-hub
pip install -r agentic/requirements.txt
```

## Verification
How you validated the change (tests, manual checks, UI pages). Include links
(e.g., Prefect UI at `http://localhost:4200`).

## Side effects / Notes
Any non-obvious side-effects, backwards compatibility notes, or migration steps.

## Next steps
Short list of follow-up tasks or recommended improvements.

---

*This template is intentionally small — keep summaries focused and link to larger design docs if needed.*
