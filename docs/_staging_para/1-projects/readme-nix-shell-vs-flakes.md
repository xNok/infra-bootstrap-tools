# README Nix Shell vs Flakes

## Goal
- Align README Nix instructions with current environment where `nix-shell` works but flakes may not be enabled.

## Findings
- User reports `nix-shell` available, flakes not available.
- Need to avoid implying flakes are universally available by default.

## Planned change
- Update README Nix section to prioritize `nix-shell` (traditional) for compatibility.
- Keep flakes as optional path with explicit prerequisite (`experimental-features = nix-command flakes`).

## Validation
- Re-read updated README section for consistency and command correctness.

## Completed
- Updated `README.md` Nix section to make `nix-shell` the most compatible/default option.
- Kept flakes as optional and explicit about enabling `nix-command` + `flakes`.
- Updated Codespaces section with both flakes-enabled and non-flakes command paths.

## Follow-up
- Enabled flakes by default in `.devcontainer/devcontainer.json` via:
	- `"containerEnv": { "NIX_CONFIG": "experimental-features = nix-command flakes" }`
- Updated README Codespaces section to reflect that flakes are enabled by default in this devcontainer.
