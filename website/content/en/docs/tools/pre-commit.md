---
title: "Pre-commit"
weight: 1
---

Pre-commit is a framework for managing and maintaining multi-language pre-commit hooks. It allows you to run checks on your code before you commit it, helping to enforce code style, prevent common mistakes, and ensure code quality.

## Tutorial

Here's how you typically set up and use `pre-commit`:

1.  **Install pre-commit:**
    If you haven't already, install pre-commit. You can often do this with pip:
    ```bash
    pip install pre-commit
    ```
    Or, use the project's setup script if available:
    ```bash
    ./bin/bash/setup.sh pre-commit
    ```

2.  **Install the Git hooks:**
    Navigate to your repository's root directory and run:
    ```bash
    pre-commit install
    ```
    This command installs the hooks into your `.git/hooks` directory. Now, pre-commit will run automatically before each commit.

3.  **Run manually (optional):**
    You can also run all pre-commit hooks on all files at any time:
    ```bash
    pre-commit run --all-files
    ```
    This is useful for checking all files in the repository, not just the staged ones.

## Usage in this Project

This project uses pre-commit hooks to automate tasks like:

*   Linting various file types (e.g., YAML, Markdown, shell scripts).
*   Checking for common Git issues (e.g., merge conflicts, large files).
*   Ensuring consistent formatting.

The configuration for pre-commit is located in the `.pre-commit-config.yaml` file at the root of the repository.

To use it, you first need to install pre-commit (e.g., via `pip install pre-commit` or using the project's `./bin/bash/setup.sh pre-commit` script) and then install the git hooks with `pre-commit install`. Once installed, the checks will run automatically every time you run `git commit`.
