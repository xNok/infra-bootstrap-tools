---
title: "Automate Testing"
parent: "changeset-release-mgmt.md"
---

# Automate Testing of Publishing Workflows

To ensure our release infrastructure is robust, we need to test the publishing workflows in PRs before merging to `main`. This involves dry-running builds and verifying artifact generation.

## Dry Runs and Validations
- **Ansible Galaxy**: Run `ansible-galaxy collection build` and lint the output to ensure `galaxy.yml` formatting is correct without calling the publish action.
- **Python**: Run `python -m build` and `twine check dist/*` to ensure package validity (PyPI compatibility).
- **Docker**: Run `docker build` without the `--push` flag, or push to a local/ephemeral registry.

## Using `workflow_call` for Testing
By converting our publish workflows to `workflow_call` reusable templates, we can invoke them from PR-triggered testing workflows (`pull_request`) by passing a dummy version and setting an `is-dry-run` flag.

```yaml
on:
  pull_request:
    paths:
      - 'agentic/**'

jobs:
  test-publish-python:
    uses: ./.github/workflows/python-package-publish.yml
    with:
      release_tag: "infra-bootstrap-tools-agentic@0.0.0-test"
      dry_run: true
```
