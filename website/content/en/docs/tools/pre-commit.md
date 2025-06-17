---
title: "Pre-commit"
weight: 1
---

## Pre-commit

Pre-commit is a framework for managing and maintaining multi-language pre-commit hooks. It allows you to run checks on your code before you commit it, helping to enforce code style, prevent common mistakes, and ensure code quality.

### Usage in this Project

This project uses pre-commit hooks to automate tasks like:

*   Linting various file types (e.g., YAML, Markdown, shell scripts).
*   Checking for common Git issues (e.g., merge conflicts, large files).
*   Ensuring consistent formatting.

The configuration for pre-commit is located in the `.pre-commit-config.yaml` file at the root of the repository.

To use it, you first need to install pre-commit (e.g., via `pip install pre-commit` or using the project's `./bin/bash/setup.sh pre-commit` script) and then install the git hooks with `pre-commit install`. Once installed, the checks will run automatically every time you run `git commit`.
