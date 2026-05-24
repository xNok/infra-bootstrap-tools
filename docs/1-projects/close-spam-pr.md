---
type: project
status: execution
description: Close spam pull requests opened by agent Jules in the repository
related_projects: []
related_resources: []
related_areas: []
---

# Close Spam Pull Requests

## Overview

The user is getting spammed with automated security/optimization PRs opened by Jules.
We need to close all of these PRs using `gh` CLI.

## Action Plan

1. Identify all open PRs in the repository.
2. Filter for those created by the automated agent `Jules` (based on branch naming conventions like `sentinel/*`, `jules-*`, etc., and authors).
3. Close the PRs programmatically using the GitHub CLI.
