# Policies

This directory contains Open Policy Agent (OPA) Rego policies used to validate code and configuration across the repository.

We use `conftest` to run these policies against our configuration files, such as GitHub Actions workflows.

## Validating Policies Locally

To run the policies locally against GitHub Actions workflows, you can use the provided wrapper script:

```bash
./bin/ci/run-conftest.sh
```

This script will automatically download the correct version of `conftest` and execute it against the workflows in `.github/workflows/`.

Alternatively, if you have `conftest` installed on your system (e.g., via `brew install conftest`), you can run it directly:

```bash
conftest test .github/workflows/*.yml -p policies/ci/
```

## Validating Policies in CI

The `.github/workflows/conftest.yml` workflow automatically runs the policies against all Pull Requests and merges to the `main` branch. This ensures that any changes to our GitHub Actions workflows comply with our defined conventions.

## Auto-generated Documentation

Documentation for the policies is auto-generated using `conftest doc`. The generated documentation can be found in the `docs/policies/` directory.

To regenerate the documentation locally, run:

```bash
conftest doc policies/ci/ -o docs/policies
```
