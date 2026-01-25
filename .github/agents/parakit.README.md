# The ParaKit System

ParaKit is a multi-agent system designed to manage the "Docs as Code" workflow for the `infra-bootstrap-tools` repository. It divides the cognitive load of documentation into specialized roles.

## Why Multiple Agents?
Managing documentation in a monorepo requires different "modes" of thinking:
1.  **Fast Capture**: Quickly jotting down notes while debugging (Analyzer).
2.  **Slow Polish**: Carefully editing and organizing content for publication (Curator).
3.  **System Oversight**: Ensuring the whole structure remains coherent (Architect).

## The Agents

### 1. ParaKit Analyzer (`parakit.analyze.agent.md`)
*   **Role**: The Scout & Scribe.
*   **Trigger**: Active development, debugging, exploration.
*   **Output**: Raw, factual notes in Staging (`1-projects`, `2-areas`, `3-resources`).
*   **Motto**: "Capture everything, format later."

### 2. ParaKit Curator (`parakit.curator.agent.md`)
*   **Role**: The Librarian & Editor.
*   **Trigger**: Feature completion, release cycles, periodic cleanup.
*   **Output**: Polished Hugo content in `website/docs` and Archives (`4-archives`).
*   **Motto**: "Graduation day for content."

### 3. ParaKit Architect (Future/Human)
*   **Role**: The System Designer.
*   **Trigger**: New major subsystems, restructuring events.
*   **Output**: Updates to `AGENTS.md`, `README.md`, and directory structures.
*   **Current State**: Performed by human maintainers or high-level prompt engineering.

## Workflow Integration

1.  **Developer** starts a task -> **Analyzer** captures notes in `1-projects`.
2.  **Developer** discovers a general pattern -> **Analyzer** updates `2-areas` or `3-resources`.
3.  **Task Complete** -> **Curator** is summoned to review `1-projects`.
4.  **Curator** moves content to `website/docs` and original notes to `4-archives`.
