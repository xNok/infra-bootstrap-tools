# OPA Policies

This directory contains Open Policy Agent (OPA) policies written in Rego that enforce various conventions and rules for the project.

## Validation and Testing

Our OPA policies are validated and documented using [conftest](https://www.conftest.dev/) as the primary tool.

### Local Testing

To test configuration files (like GitHub Actions workflows) against the policies locally, you can use the `conftest` CLI tool.

1.  **Install conftest:** Follow the installation instructions for your platform on the [conftest releases page](https://github.com/open-policy-agent/conftest/releases).
2.  **Run tests:** Run `conftest test` specifying the target files and the policy directory.

    For example, to test CI workflows against CI policies:
    ```bash
    conftest test .github/workflows/*.yml -p policies/ci/
    ```

### CI/CD Integration

These policies are automatically enforced in CI using a dedicated GitHub Actions workflow (`.github/workflows/conftest.yml`), which uses `conftest` via the `bin/ci/run-conftest.sh` script to check configuration files.
