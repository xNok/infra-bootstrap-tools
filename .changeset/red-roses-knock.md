---
"infra-bootstrap-tools": minor
---

Migrating Terraform Workflow to Github Action

* Experimenting with [changesets](https://github.com/changesets/changesets), the aim is to have a better way to track the changelog for this monorepo. Changesets are designed for Node.js projects, but I quite like the workflow and want to see if we can have a universal changeset system.
* Experimenting with [1Password CI/CD Integrations](https://developer.1password.com/docs/ci-cd/), I have been managing secrets with GitHub Actions, but I find it laborious. I would like to have a permanent secret management solution that can be easily integrated into any workflow. This should make running Terraform locally during the development phase much easier.