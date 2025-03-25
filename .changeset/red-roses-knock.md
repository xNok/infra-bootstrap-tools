---
"infra-bootstrap-tools": minor
---

Migrating Terraform Workflow to Github Action

## Experiments

* Experimenting with [changesets](https://github.com/changesets/changesets), the aim is to have a better way to track the changelog for this monorepo. Changesets are designed for Node.js projects, but I quite like the workflow and want to see if we can have a universal changeset system.
* Experimenting with [1Password CI/CD Integrations](https://developer.1password.com/docs/ci-cd/), I have been managing secrets with GitHub Actions, but I find it laborious. I would like to have a permanent secret management solution that can be easily integrated into any workflow. This should make running Terraform locally during the development phase much easier.
    * Introduce [composit action](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action) to manage loading secrets. I can't assume that everyone will be using 1password, thus I should provide the option to use good old Githb Action secret. Having to update each action seems like a pain, intead a single composite action can be reuse in the workflows to deal with this.

## Learnings

Github Action has several option we can leverage to build the Terraform worflow when it comes to manage parallelism of different stack/workspace
* [Reusable Workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows)
* [Dispatched workflows](https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/manually-running-a-workflow#running-a-workflow-using-the-rest-api)
* [Composite Actions](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action)

You can't use secrets in Composite workflow directly so while it seems nice in terms of building a liabrary of automation, it's becomes much more verbose to configure. I want to find a leaner way to manager secret in a project that should not assume what stack people choose.

Composite action can still be used to make the workflow smaller and easier to read, and potentially reusable.