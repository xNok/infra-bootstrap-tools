# Project: Revive PR #248 (Fix website + add pagefind with simplified URLs)

## Objective
Revive and land the website modernization and search integration originally contributed in [PR #248](https://github.com/xNok/infra-bootstrap-tools/pull/248) by Dumindu Madunuwan (`@dumindu`).

## PR 248 Context & History
- **Author**: Dumindu Madunuwan (`@dumindu`), author of the Hugo E25DX theme.
- **Original Branch**: `dumindu:main` -> `xNok:main` (PR #248).
- **Status**: Closed on 2026-11-21 at 19:55:34 UTC by the author after sitting for ~10 days without merge.
- **Key Changes in PR 248**:
  1. Updated E25DX theme submodule to upstream `https://github.com/dumindu/E25DX.git` at commit `888f1bb6bb` (which includes native pagefind search modals, adaptable logo color, and clean responsive layouts).
  2. Integrated Pagefind client-side search UI in Hugo templates (`pagefind-head.html`, `home.html`, etc.).
  3. Added sub-section support with proper right sidebar and next/previous page navigation footer for `docs/tools/` sub-items via `groupSection: tools` in `website/data/en/docs/sidebar.yml`.
  4. Simplified documentation and blog URL hierarchy (renamed `gs1.getting_started.md` -> `a2.getting-started.md`, etc.).
  5. Added hero SVG and logo SVG assets, updated hero configuration in `website/data/en/home/hero.yaml`.
  6. Cleaned up obsolete archetypes, CSS, and layouts that duplicated upstream theme functionality.
  7. Updated cross-links across `README.md`, `docs/1-projects/docker-swarm-env.md`, and `docs/3-resources/caddy.md`.

## Discoveries & Gaps Identified
During analysis and local verification of the PR 248 commit tree against current `origin/main` (`367d9fa`):
1. **Zero Conflict with Main**:
   Between merge-base `0cb070e` and latest `origin/main` (`367d9fa`), only Kubernetes tenant isolation and documentation were modified. Zero files overlap with PR 248.
2. **Pagefind Automation Gap in PR 248**:
   In PR 248, `enablePageFind: true` was added to `website/hugo.yaml`, but `pagefind` was neither in the Nix dev environment nor invoked in `bin/ci/build-website.sh`. Local builds and GitHub Pages deployments would have missing search indices unless manually run.
   - *Fix*: Added `pkgs.pagefind` to `docsPackages` in `bin/nix/common.nix`, and added `pagefind --site public` to `bin/ci/build-website.sh`.
3. **URL Portability for Hero and Pagefind**:
   - In PR 248, `btn_primary.url` in `website/data/en/home/hero.yaml` was hardcoded to `/infra-bootstrap-tools/docs`, breaking local preview servers (`http://localhost:1313`). Changing to `docs` allows Hugo's `absLangURL` to dynamically resolve correctly for both local and production base URLs.
   - In `website/layouts/_partials/pagefind-head.html`, the bundle path was hardcoded to `/infra-bootstrap-tools/pagefind/`. Changing to `{{ "pagefind/" | relURL }}` ensures local testing works on `/pagefind/` while GitHub Pages uses `/infra-bootstrap-tools/pagefind/`.
4. **Outdated Doc Links in Stacks README**:
   - `stacks/README.md` referenced old doc filenames (`gs1.getting_started.md`, `a2.portainer.md`, `b3.docker_swarm.md`). These should be updated to maintain doc link integrity.
5. **Git Submodule Pointer**:
   - `website/themes/e25dx` cleanly tracks `https://github.com/dumindu/E25DX.git` at commit `888f1bb6bb06b14adb9c22bdc4e7f6b17eaadef6`.
6. **Pre-commit & Build Verification**:
   - Tested Hugo build: 30 pages generated in ~100ms.
   - Tested Pagefind index generation: 26 pages indexed in ~80ms.
   - Tested pre-commit suite (yamllint, shellcheck, ansible-lint, terraform-docs, conftest): 100% Passed.

## Proposed Commit Structure
- **Commit 1 (Author: Dumindu Madunuwan)**:
  `feat(website): update E25DX theme, simplify docs URLs, and add pagefind UI`
  Contains all the core changes from PR #248 cleanly applied onto latest `main`.
- **Commit 2 (Author: Alexandre Couedelo / xNok)**:
  `feat(ci): integrate pagefind into nix docs shell and automated website build`
  Contains `common.nix` package additions, `build-website.sh` automation, dynamic `relURL` bundle path, portable hero URL, and updated links in `stacks/README.md`.
