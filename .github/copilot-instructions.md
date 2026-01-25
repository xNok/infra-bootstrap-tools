## Purpose
This file tells AI coding assistants how to be productive in the infra-bootstrap-tools monorepo. Keep guidance short, actionable and always reference concrete files or commands in the repo.

## 1. Your role (developer / architect)
As a contributor you may switch hats depending on the task — make the active role explicit in your work and in the commit/PR description.

- Developer: implement features and tasks described in the project's docs. Work from the docs first (see section 2).
- Solution Architect: review design choices, flag risks, propose improvements, and ensure designs align with project goals. Update docs first when proposing architecture changes.

Make sure code and design decisions are reflected in the docs and linked from `docs/` (see Docs First below).

## 2. Core workflow — Staging PARA (mandatory)
The `docs/` folder is the single source of truth, specifically organized via the Staging PARA system. Follow this process:

1. **Capture**: Start every task by creating or updating a note in `docs/_staging_para/1-projects/<your-task>.md`. Use this to plan, log findings, and draft changes.
2. **Refine**: As you work, refine these notes.
3. **Publish**: Permanent documentation should be migrated to `website/docs` (handled by the Curator agent).
4. **Archive**: Once done, move the raw notes to `docs/_staging_para/4-archives/<your-task>.md`.

This ensures that "Work in Progress" is captured but separated from "Published Docs".

## Quick orientation (big picture)
- Monorepo with three main families:
  - `agentic/` — Python package implementing the Jules agent, Prefect workflows and deployment scripts (key files: `agentic/workflows/jules_workflow.py`, `agentic/deployment/deploy.py`, `agentic/jules/agent.py`, `agentic/jules.schema.json`).
  - `ansible/` — Ansible collection and roles. The Makefile builds/installs the collection before running playbooks (`Makefile` target `install-collection`, `up`, `down`).
  - `stacks/` — Docker compose stacks (e.g., Prefect + MCP Hub under `stacks/prefect`).

## Key developer workflows (executable examples)
- Enable the helper CLI (recommended):
  - source the helper: `source ./bin/bash/ibt.sh` (this provides `ibt` subcommands used throughout the README). See `bin/bash/ibt.sh`.
- Bring up Prefect + MCP Hub for agent development:
  - `ibt stacks run prefect mcp-hub` or `cd stacks/prefect && docker compose -f prefect.local.yaml -f mcp-hub.local.yaml up`
- Install Python deps for `agentic` and configure secrets:
  - `pip install -r agentic/requirements.txt`
  - `cp agentic/.env.example agentic/.env` then edit the file. Required env vars: `GITHUB_TOKEN`, `JULES_API_KEY`, and depending on model `GOOGLE_API_KEY` or `OPENAI_API_KEY`. See `agentic/QUICKSTART.md` and `agentic/README.md`.
- Deploy the Jules workflow locally (note: this runs in foreground):
  - `cd agentic && python deployment/deploy.py`
  - The script preloads MCP servers and then calls `jules_agent_workflow.serve(...)`. See `agentic/deployment/deploy.py` for flags (`--skip-mcp-preload`, `--deploy-only`).
- Full infra provisioning via Ansible (cloud):
  - `make up` (Makefile triggers building/installing Ansible collection then runs playbook). `make down` tears down.

## Project-specific patterns & conventions
- Monorepo workspaces are declared in top-level `package.json` (node workspaces are used only for tooling/release management). Expect multiple package types (Python package, Ansible collection, stacks). Use `changesets` for releases (`npx changeset add` -> `npm run release`).
- Secrets: `.env` is used; `agentic/.env.example` documents required variables. Never hardcode credentials — the repo follows this pattern consistently.
- Prefect usage: local development uses `serve()` pattern (the deployment script calls the flow's `serve` rather than a cloud deployment). The flow is designed to run in foreground for local debugging (ctrl+C to stop).
- MCP Hub integration: the repo uses an MCP Hub (default `http://localhost:3000`) and two MCP servers are commonly preloaded: GitHub (stdio/http) and Jules (OpenAPI from `agentic/jules.schema.json`). See `agentic/deployment/deploy.py` for exact POST payloads and health-check logic.

## Where to look for examples (concrete files to inspect)
- Agent + workflows: `agentic/workflows/jules_workflow.py`, `agentic/jules/agent.py`, `agentic/jules/models.py`.
- Deployment automation: `agentic/deployment/deploy.py` (contains health checks, MCP preloads, environment checks and serve/deploy flow usage).
- Env template: `agentic/.env.example`.
- Stacks: `stacks/prefect/*` (docker compose files for Prefect + MCP Hub). Prefect UI defaults: `http://localhost:4200`.
- Ansible collection build & make targets: top-level `Makefile` and `ansible/` directory.

## Behavioural guidance for code changes
- When modifying `agentic` flows prefer minimal, well-tested changes: flows are sensitive to environment variables and MCP tool signatures. If you change a task interface, update `agentic/jules.schema.json` or the MCP preloading logic accordingly.
- Small, local verification loop:
  1. Start Prefect + MCP Hub (`ibt stacks run prefect mcp-hub`).
  2. Install deps and set `.env`.
  3. Run `python agentic/deployment/deploy.py` (or run a single task/flow directly from `agentic/workflows/jules_workflow.py`).
  4. Use Prefect UI to inspect logs and trace errors.

## Quick troubleshooting cheatsheet
- MCP Hub unreachable: check `stacks/prefect` compose files and `docker ps`. Health path: `http://localhost:3000/health`.
- Missing envs: `deploy.py` will list missing env vars (GITHUB_TOKEN, JULES_API_KEY, GOOGLE_API_KEY/OPENAI_API_KEY depending on `LLM_MODEL`).
- Flow not showing in Prefect UI: ensure Prefect API URL is set (`PREFECT_API_URL`), and check `deploy.py` output — the script sets `PREFECT_API_URL` and calls flow serve.

## Merge guidance
- Preserve any project-specific examples and only replace outdated commands. Prefer commands and file references from the `README.md`/`QUICKSTART.md`/`IMPLEMENTATION.md` when merging.
