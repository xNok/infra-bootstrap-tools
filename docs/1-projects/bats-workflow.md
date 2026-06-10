# Bats workflow
Goal: Create a GitHub Actions workflow to run bats tests when scripts in `bin/` are updated.
Location of workflow: `.github/workflows/bats.yml`
Trigger: Push or pull request modifying `bin/**`
Steps:
1. Checkout code
2. Install bats
3. Run bats on \`bin/tests/ci/*.bats\`
