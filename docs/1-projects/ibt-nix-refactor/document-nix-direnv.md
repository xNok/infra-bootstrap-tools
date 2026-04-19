# Task: Document Nix Direnv Workflow

Thoughts:
- The user had an issue where launching the IDE via taskbar shortcut left the IDE without the Nix development environment.
- This broke features like pre-commit, yamllint, and antigravity tools running in the standard UI.
- The workflow to resolve this is creating a per-project `.envrc` and using Home Manager to set up `nix-direnv`.
- I have directly created the permanent documentation for this workflow under `website/content/en/docs/tools/direnv.md`.
- No further action required for this task.
