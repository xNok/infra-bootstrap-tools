---
title: "Pre-commit"
weight: 1
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

If you frequently start new projects or clone repositories and want pre-commit to be active by default (if a configuration exists), you can set it up globally. This method utilizes Git's `init.templateDir` feature.

1.  **Configure Git's Template Directory:**
    Tell Git to use a specific directory as a template for new repositories:
    ```bash
    git config --global init.templateDir ~/.git-template
    ```
    You can choose a different directory if you prefer, just ensure it's consistent in the next step.
2.  **Initialize Pre-commit in the Template Directory:**
    Run the following command:
    ```bash
    pre-commit init-templatedir ~/.git-template
    ```
    (If you chose a different directory in the previous step, replace `~/.git-template` accordingly.)

**Benefit:** With this global setup, any new repository you initialize (`git init`) or clone will automatically have pre-commit's hook installed. If a repository doesn't have a `.pre-commit-config.yaml` file, pre-commit will simply do nothing, so it's safe to enable globally. You'll no longer need to remember to run `pre-commit install` for every new project!

## Building Your Configuration (.pre-commit-config.yaml)

The heart of pre-commit is the `.pre-commit-config.yaml` file. This file, placed at the root of your repository, tells pre-commit which checks to run.

### Core Structure Explained

A typical configuration involves a list of repositories, each with specific hooks:

*   `repos`: This is a top-level key, and it takes a list of repository mappings. Each item in the list specifies a Git repository that contains pre-commit hooks.
    *   `repo`: The URL of the repository hosting the hooks (e.g., `https://github.com/pre-commit/pre-commit-hooks`).
    *   `rev`: This is crucial. It specifies the version of the hooks to use, by pinning to a Git tag, SHA, or branch. **Always use a specific tag or SHA** (not a branch like `master`) to ensure your builds are reproducible and don't unexpectedly break when the remote repository updates.
    *   `hooks`: A list under each `repo` entry. Each item here defines a specific hook to use from that repository.
        *   `id`: The unique identifier of the hook (e.g., `trailing-whitespace`, `check-yaml`). You can find available hook IDs in the documentation of the hook repository.

### A Practical Starter Configuration

Here's a basic `.pre-commit-config.yaml` to get you started. This configuration uses some of the most common general-purpose hooks from the official `pre-commit-hooks` repository:

```yaml
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0  # Check for the latest stable version on the pre-commit-hooks repo!
    hooks:
    -   id: trailing-whitespace
    -   id: end-of-file-fixer
    -   id: check-yaml
    -   id: check-added-large-files
# Add other repositories and their specific hooks below
# -   repo: ...
#     rev: ...
#     hooks:
#     -   id: ...
```

**Note:** Versions for hooks change over time. It's good practice to occasionally check the `pre-commit-hooks` repository (or any other hook repositories you use) for the latest stable version tag and update your `rev` accordingly.

## Essential Hooks for Every Project

While `pre-commit` can run any type of script, a few hooks are widely considered essential for maintaining code quality, consistency, and security across most projects. Here are some highly recommended ones:

### Code Formatting

Consistent code formatting is key to readability and collaboration.

*   **`black` (Python):** An opinionated Python code formatter that ensures uniformity with minimal configuration.
*   **`prettier` (Web - JS/TS, HTML, CSS, Markdown, etc.):** A versatile and opinionated formatter supporting a wide array of web development languages and file types.

### Linting & Static Analysis

These tools help catch errors, potential bugs, and style violations before they become bigger problems.

*   **`ruff` or `flake8` (Python):** `flake8` is a popular Python linter that combines PyFlakes, pycodestyle, and McCabe; `ruff` is a newer, extremely fast Python linter written in Rust, capable of replacing `flake8`, `isort`, and many other tools.
*   **`eslint` (JavaScript/TypeScript):** The standard linter for JavaScript and TypeScript, helping to find and fix problems in your code.

### Security

Preventing accidental credential exposure is paramount.

*   **`detect-secrets`:** This hook scans for secrets (like API keys or passwords) in your code to prevent them from being committed.

### Import Sorting

Clean and organized imports make your code easier to navigate.

*   **`isort` (Python):** Automatically sorts Python imports alphabetically and separates them into sections and types.

## Advanced Techniques & Customization

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

Sometimes, you might have project-specific scripts or checks that aren't part of a public hook repository. Pre-commit allows you to define "local" hooks.

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
    This tells pre-commit to run `my_custom_script.sh` for any changed Python (`.py`) files. The `language: script` type is very flexible; for specific environments like Python or Node, you can specify those to manage dependencies if needed.

### Friendly Reminder for Teams (Global Template Enhancement)

A common hiccup is when a team member clones a repository but forgets to run `pre-commit install`. If you've adopted the "Global Setup" using `init.templateDir`, you can enhance the template's pre-commit hook to provide a friendly reminder.

1.  **Locate Your Template:** This assumes you've configured `init.templateDir` (e.g., to `~/.git-template`). The hook script to edit would be `~/.git-template/hooks/pre-commit`.
2.  **Edit or Create `~/.git-template/hooks/pre-commit`:**
    If this file already exists (e.g., from `pre-commit init-templatedir`), you can prepend the following logic. If it doesn't exist, create it with this content:

    ```bash
    #!/bin/bash

    # Check if a .pre-commit-config.yaml exists in the current repo
    # AND if the local .git/hooks/pre-commit is NOT the one managed by pre-commit
    # (or more simply, if it's missing, as pre-commit would have created it)
    if [ -f .pre-commit-config.yaml ] && ! [ -f .git/hooks/pre-commit ]; then
        echo '--------------------------------------------------------------------' >&2
        echo 'Warning: .pre-commit-config.yaml detected, but hooks are not installed.' >&2
        echo 'Please run `pre-commit install` to enable automated checks.' >&2
        echo '--------------------------------------------------------------------' >&2
    fi

    # If pre-commit is installed in .git/hooks, this script will be replaced by it.
    # If not, this message serves as a reminder.
    # If pre-commit *is* installed, it will manage its own execution.
    # If you had existing content in a global pre-commit hook,
    # ensure `pre-commit init-templatedir` merged it correctly or re-add it here.
    ```
    Make sure the script is executable: `chmod +x ~/.git-template/hooks/pre-commit`.

**How it works:** When you `git init` or `git clone` a new repository, Git copies everything from `~/.git-template` into the new repository's `.git` directory. If this script is your `~/.git-template/hooks/pre-commit`, it will run before any commit. It checks if a `.pre-commit-config.yaml` is present in the project and if the actual `.git/hooks/pre-commit` (which `pre-commit install` would create) is missing. If both conditions are true, it prints a helpful reminder to run `pre-commit install`. Once `pre-commit install` is run in the repository, it replaces the `.git/hooks/pre-commit` with its own, and this reminder logic is no longer directly executed (pre-commit takes over).

## Pre-Commit in a Team and CI/CD Environment

While pre-commit shines on individual developer machines, its benefits multiply when integrated into team workflows and CI/CD pipelines.

### CI/CD Integration: The Final Gatekeeper

Even with pre-commit hooks installed locally, someone might accidentally commit without hooks (e.g., using `git commit --no-verify`) or have an outdated hook configuration. Your CI/CD pipeline can act as the ultimate gatekeeper.

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
    # If your hooks install their own dependencies (common), this might be minimal.

- name: Run pre-commit checks
  run: pre-commit run --all-files
```

If any hook fails in the CI environment, the pipeline step will fail, preventing the merge or deployment of problematic code.

### Introducing to Existing Projects and Teams

Rolling out pre-commit to an established project or team requires a thoughtful approach:

1.  **Start Small and Gentle:** Begin by introducing a `.pre-commit-config.yaml` with a very small set of low-impact, auto-fixing hooks. Good candidates are:
    *   `trailing-whitespace`
    *   `end-of-file-fixer`
    *   `check-yaml` (if you use YAML)
    *   `check-json` (if you use JSON)
    These hooks are generally uncontroversial and provide immediate, visible benefits.
2.  **Communicate the "Why":** Explain to your team the benefits: catching errors early, reducing "linting commits," standardizing code style, and preventing broken builds. Focus on how it helps everyone save time and frustration.
3.  **Initial Codebase Clean-up:** Before wider adoption or adding more aggressive hooks (like formatters or complex linters), decide on a strategy for the existing codebase:
    *   **One-time Big Clean-up:** Run `pre-commit run --all-files` once (perhaps in a dedicated branch) to fix all existing issues. This gets everything to a consistent state quickly but can result in a large initial commit.
    *   **Incremental Clean-up:** Add new hooks gradually. Encourage team members to run `pre-commit run --all-files` on the files they are currently working on. This spreads the clean-up effort over time.
4.  **Gradually Introduce More Hooks:** Once the team is comfortable, progressively add more hooks. Discuss new additions with the team, especially opinionated formatters like `black` or `prettier`.
5.  **Documentation and Support:** Provide clear instructions on how to install and use pre-commit (like this document!). Be available to help teammates troubleshoot. The global setup (`init.templateDir`) or the reminder script mentioned in "Advanced Techniques & Customization" can be particularly helpful for ensuring everyone has it active.

By following these steps, you can smoothly integrate pre-commit and elevate your team's code quality and development practices.

## Conclusion

From the initial "Aha!" moment of realizing there *has* to be a better way than manual checks and "oops" commits, we've explored how `pre-commit` transforms your development workflow. By automating checks for everything from whitespace errors and secret detection to code formatting and linting, pre-commit acts as your tireless local guardian of code quality.

It empowers individual developers to catch issues before they become team problems, streamlines collaboration by enforcing consistency, and integrates seamlessly into CI/CD pipelines to serve as a final quality gate. The journey from potentially messy, error-prone commits to a clean, automated, and protected workflow is not just possible, but straightforward with pre-commit.

The key benefits are clear: significant time saved for developers and reviewers, a reduction in common errors slipping into the codebase, and the ability to maintain high standards of code quality with minimal ongoing effort.

If you haven't already, incorporating `pre-commit` into your projects is a small investment that pays substantial dividends in productivity, code robustness, and developer sanity. Give it a try – your future self (and your team) will thank you!
