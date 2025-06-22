---
title: "Pre-commit: Your First Line of Defense for Clean Code"
slug: pre-commit
description: > 
    Learn how to use the pre-commit framework to automate code quality checks before they ever leave your machine.
    This guide covers everything from installation and configuration to creating custom hooks and integrating with your CI/CD pipeline, helping you and your team maintain high standards with minimal effort.
tags:
- git
- git-hooks
- devops
- code-quality
- developer-tools
- github-actions
---

Ever accidentally pushed secrets to a repository? Or maybe you've pushed unformatted code, only to have to create a follow-up "linting" commit? We've all been there. These small mistakes can lead to failed CI/CD pipelines and frustrating delays, all because of checks that could have been run locally.

Git hooks are a powerful tool to prevent these issues by running scripts before you commit or push. However, sharing and standardizing these hooks across a team or project can be challenging.

This is where pre-commit comes in. Pre-commit is an easy-to-use framework for managing and sharing multi-language git hooks, helping you catch issues before they even leave your workstation.

## Getting Started: The Right Setup

Before you can harness the power of pre-commit, you need to install it and configure it for your projects.

### Installation

You have several ways to install pre-commit:

*   **macOS (Recommended):**
    ```bash
    brew install pre-commit
    ```
*   **Python/Pip (Cross-Platform):**
    ```bash
    pip install pre-commit
    ```
*   **Other Methods:** For installations using Conda, or on Windows, please refer to the [Official Documentation](link-to-be-added).

### Project-Specific Setup (The Standard Way)

This is the most common approach for enabling pre-commit in a specific project:

1.  **Create a Configuration File:** In the root of your repository, create a file named `.pre-commit-config.yaml`. This file will define the hooks pre-commit should run. (We'll cover how to populate this file in the next section).
2.  **Install Hooks:** Navigate to your repository's root directory in your terminal and run:
    ```bash
    pre-commit install
    ```
    This command installs the git hooks into your repository's `.git/hooks` directory. From now on, pre-commit will automatically run its checks before each commit you make in this specific repository.

### Global Setup (The "Set It and Forget It" Method)

If you frequently start new projects or clone repositories and want pre-commit to be active by default (if a configuration exists), you can set it up globally. This method utilises Git's `init.templateDir` feature.

1.  **A Configuration File:** All your repository, must have a `.pre-commit-config.yaml`. This file will define the hooks pre-commit should run. The best would be to use a template repository with a minimal pre-comit file.
2.  **Configure Git's Template Directory:**
    Tell Git to use a specific directory as a template for new repositories:
    ```bash
    git config --global init.templateDir ~/.git-template
    ```
    You can choose a different directory if you prefer, just ensure it's consistent in the next step.
3.  **Initialize Pre-commit in the Template Directory:**
    Run the following command:
    ```bash
    pre-commit init-templatedir ~/.git-template
    ```
    (If you chose a different directory in the previous step, replace `~/.git-template` accordingly.)

This has a mojar **Benefit:** With this global setup, any new repository you initialise (`git init`) or clone will automatically have pre-commit's hook installed. If a repository doesn't have a `.pre-commit-config.yaml` file, pre-commit will simply do nothing, so it's safe to enable globally. Yet I like to go one step further by adding a default hook `~/.git-template/hooks/pre-commit` that would systematically fail if a repository doesn't have a `.pre-commit-config.yaml`. here is the content of the hook

```bash
#!/usr/bin/env bash
if [ -f .pre-commit-config.yaml ]; then
    echo 'pre-commit configuration detected, but `pre-commit install` was never run' 1>&2
    exit 1
fi
```

## Building Your Configuration (.pre-commit-config.yaml)

The heart of pre-commit is the `.pre-commit-config.yaml` file. This file, placed at the root of your repository, tells pre-commit which checks to run. Here is a small example of such configuration.

```
# https://github.com/xNok/infra-bootstrap-tools/blob/main/.pre-commit-config.yaml
repos:
  # Lint all yam files
  - repo: https://github.com/adrienverge/yamllint.git
    rev: v1.29.0
    hooks:
      - id: yamllint
  # Runs Ansible lint
  - repo: https://github.com/ansible/ansible-lint
    rev: v24.7.0
    hooks:
      - id: ansible-lint
        args:
          - "ansible"
        additional_dependencies:
          - ansible
```

### Core Structure Explained

A typical configuration involves a list of repositories, each with specific hooks:

*   `repos`: This is a top-level key, and it takes a list of repository mappings. Each item in the list specifies a Git repository that contains pre-commit hooks.
    *   `repo`: The URL of the repository hosting the hooks (e.g., `https://github.com/pre-commit/pre-commit-hooks`). This is a very nie way to manage dependencies, when to know ore about the tool, then head to the repository.
    *   `rev`: It specifies the version of the hooks to use, by pinning to either a Git tag, SHA, or branch. But it is advised to **Always use a specific tag or SHA** (not a branch like `master`) to ensure your linting doesn't unexpectedly break when the remote repository updates.
    *   `hooks`: A list under each `repo` entry. Each item here defines a specific hook to use from that repository.
        *   `id`: The unique identifier of the hook (e.g., `trailing-whitespace`, `check-yaml`). You can find available hook IDs in the hook repository documentation. or simply the `.pre-commit-hooks.yaml` at the repo's root.

### A Practical Starter Configuration

Here's a basic `.pre-commit-config.yaml` to get you started. For this example, I advise you to head to Github and have a look at [pre-commit/pre-commit-hooks/blob/main/.pre-commit-hooks.yaml](https://github.com/pre-commit/pre-commit-hooks/blob/main/.pre-commit-hooks.yaml). This is the list of simple hooks that the `pre-commit` team has implemented, and where you can find the `id` of each of the relevant hooks you may wanna use. I's say `trailing-whitespace` and `end-of-file-fixer` are really useful, thus the configuration would look like this. 

```yaml
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0  # Check for the latest stable version on the pre-commit-hooks repo!
    hooks:
    -   id: trailing-whitespace
    -   id: end-of-file-fixer
# Add other repositories and their specific hooks below
# -   repo: ...
#     rev: ...
#     hooks:
#     -   id: ...
```

**Note:** Versions for hooks change over time. It's good practice to occasionally check the `pre-commit-hooks` repository (or any other hook repositories you use) for the latest stable version tag and update your `rev` accordingly. Or have automation in place, like Renovate or Dependabot, to update those regularly.

You can find a large list of pre-existing hooks on [pre-commit website](https://pre-commit.com/hooks.html), see what's there and start validation. From my experience, this list is far from exhaustive; instead, I prefer checking the tools I like to use for a `.pre-commit-hooks.yaml` and see if hooks are available.

## Good to know when using pre-commit

Once you're comfortable with the basics, pre-commit offers more advanced features for fine-tuning your workflow.

### Running Hooks Manually

While hooks run automatically on `git commit`, you might want to trigger them manually at other times:

*   **Run a specific hook:** To execute a single hook (e.g., to test its configuration or apply its changes without committing), use:
    ```bash
    pre-commit run <hook_id>
    ```
    Replace `<hook_id>` with the actual ID from your configuration file.
*   **Run on all files:** To run all configured hooks across every tracked file in your repository (not just staged changes), use:
    ```bash
    pre-commit run --all-files
    ```
    This is useful for an initial cleanup or when adding new hooks to an existing project.

### Creating Your Own Local Hooks

Sometimes, you might have project-specific scripts or checks not part of a public hook repository. Pre-commit allows you to define "local" hooks.

1.  **Write Your Script:** Create your script (e.g., a shell script, Python script) in your repository. For this example, let's say you create `my_custom_script.sh`.
2.  **Define in `.pre-commit-config.yaml`:** Add a local hook entry to your configuration:
    ```yaml
    # In your .pre-commit-config.yaml
    -   repo: local
        hooks:
        -   id: my-custom-check
            name: My custom check
            entry: ./my_custom_script.sh # Path to your script
            language: script             # Or python, node, etc.
            files: \.(py)$               # Example: regex to run only on Python files
            # verbose: true              # Uncomment for more output
            # args: [--custom-arg]       # Optional arguments for your script
    ```
    
   This tells pre-commit to run `my_custom_script.sh` for any changed Python (`.py`) files. The `language: script` type is very flexible; for specific environments like Python or Node, you can specify those to manage dependencies if needed. I have mostly experimented with `bash` hooks. Still, pre-commit is very smart regarding working environments, as it creates an isolated runtime environment for the tools and required dependencies. Not all hooks, sadly, have leveraged the dependency feature, and you may have to install the tools yourself to be able to run the hook (I'm thinking of terraform, for instance) 

## Pre-Commit in a Team and CI/CD Environment

While pre-commit shines on individual developer machines, its benefits multiply when integrated into team workflows and CI/CD pipelines. Even with pre-commit hooks installed locally, someone might accidentally commit without hooks (e.g., using `git commit --no-verify`) or have an outdated hook configuration. Your CI/CD pipeline can act as the ultimate gatekeeper.

By running pre-commit checks in your CI pipeline, you ensure that no code violating your project's standards gets merged. The typical command for this is:

```bash
pre-commit run --all-files
```

This command checks all files in the repository, not just the changed ones, ensuring comprehensive validation.

**Conceptual CI Pipeline Step (e.g., GitHub Actions):**

```yaml
# Example for a GitHub Actions workflow
# ... (other steps like checkout, setup python/node, etc.)

- name: Install pre-commit and dependencies
  run: |
    pip install pre-commit
    # Install any other dependencies your hooks might need (e.g., linters)
    # This might be minimal if your hooks install their own dependencies (common).

- name: Run pre-commit checks
  run: pre-commit run --all-files
```

This is nice for having a conceptual pipeline that would work with any CI system, but if you use GitHub actions, you don't need to bother; simply use the [official action](https://github.com/pre-commit/action).

```
jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-python@v3
    - uses: pre-commit/action@v3.0.1
```

And with the CI integration, the loop is completed, having the same validation in developer environments as in the CI environment. If the pipeline fails, fix it locally by running pre-commit.

## Conclusion

From the initial "Aha!" moment of realizing there *has* to be a better way than manual checks and "oops" commits, we've explored how `pre-commit` transforms your development workflow. By automating checks for everything from whitespace errors and secret detection to code formatting and linting, pre-commit acts as your tireless local guardian of code quality.

It empowers individual developers to catch issues before they become team problems, streamlines collaboration by enforcing consistency. It integrates seamlessly into CI/CD pipelines to serve as a final quality gate. With pre-commit, the journey from potentially messy, error-prone commits to a clean, automated, and protected workflow is not only possible but straightforward.

The key benefits are clear: significant time saved for developers and reviewers, reduced common errors slipping into the codebase, and the ability to maintain high code quality standards with minimal ongoing effort.

If you haven't already, incorporating `pre-commit` into your projects is a small investment that pays substantial dividends in productivity, code robustness, and developer sanity. Give it a try – your future self (and your team) will thank you!
