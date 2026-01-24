# Staging PARA Workflow

This directory serves as the **Staging Area** for our "Docs as Code" workflow, organized using a hybrid PARA (Projects, Areas, Resources, Archives) method.

## Workflow Overview

We separate "Work in Progress" (Staging) from "Published Docs" (Website). This folder (`docs/_staging_para`) is where knowledge is captured and refined before publication.

### 1. The Capture Phase (Drafting)
During a Pull Request (PR) or active development:
- **Drop raw notes, logs, or diagrams** directly into the relevant folder.
    - `1-projects`: For active tasks (e.g., `agentic-workflow.md`).
    - `3-resources`: For tools and reference material (e.g., `caddy.md`, `portainer.md`).
- **Do not worry about formatting.** Speed and capture are the priorities here.
- Use `2-areas` for broader categories like `infra`, `dev`, or `sec` if a specific project or resource doesn't fit.

### 2. The Refine Phase (Publishing)
Periodically, or when a feature is complete:
- Review the content in Staging.
- **Migrate finished content** to the public documentation site at `website/docs`.
- Ensure the migrated content is properly formatted and integrated into the site's structure.

### 3. The Archive Phase (Cleanup)
Once content has been successfully migrated to the website:
- **Move the original raw notes** from `1-projects`, `2-areas`, or `3-resources` to `4-archives`.
- This keeps the active folders clean while preserving the history of our thought process and raw data.

## Folder Structure

- **1-projects/**: Active initiatives with a beginning and an end.
- **2-areas/**: Ongoing responsibilities (`infra`, `dev`, `sec`).
- **3-resources/**: Topics or themes of ongoing interest (`caddy`, `portainer`).
- **4-archives/**: Completed projects and migrated notes.
