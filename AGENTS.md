# Agent Guidelines for `infra-bootstrap-tools`

This repository follows a strict "Docs as Code" workflow. As an agent, your primary responsibility is to ensure that every action is captured, documented, and eventually published.

## The PARA Workflow

We use a hybrid PARA method for knowledge management:
- **Projects (`docs/1-projects`)**: Active tasks with a deadline.
- **Areas (`docs/2-areas`)**: Ongoing responsibilities.
- **Resources (`docs/3-resources`)**: Topics of interest.
- **Archives (`docs/4-archives`)**: Completed work.

## Your Instructions

1.  **Capture First**: Before writing code, or as you explore the codebase, create a scratchpad note in `docs/1-projects/<current-task>.md`.
    - Dump your thoughts, plans, and discoveries there.
    - Don't worry about formatting initially.
    - **Convention**: Each project must have exactly one single markdown file at the root of `1-projects` (e.g., `feature-x.md`). If a number of additional documents or assets are needed for the project, create a dedicated folder with the same name (e.g., `feature-x/`) to contain them.
2.  **Refine**: As the task solidifies, clean up the note. If the information is permanent documentation, prepare it for migration to `website/docs`.
3.  **Context**: Always check `docs` for existing context on active projects.
4.  **No "Hidden" Knowledge**: Do not rely on internal memory. If you learn something about the system, write it down in the appropriate Staging folder.
