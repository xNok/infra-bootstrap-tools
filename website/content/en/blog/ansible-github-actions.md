---
title: "How to Run an Ansible Playbook using GitHub Actions"
date: 2024-01-05
author: xNok
summary: Automate your infrastructure deployment by running Ansible playbooks through GitHub Actions CI/CD workflows.
canonical_url: https://faun.pub/how-to-run-an-ansible-playbook-using-github-action-42430dec944
tags:
  - Ansible
  - GitHub Actions
  - CI/CD
  - Automation
  - DevOps
---

# How to Run an Ansible Playbook using GitHub Actions

GitHub Actions provides powerful CI/CD capabilities. Combining it with Ansible enables automated infrastructure deployment triggered by code changes, creating a true GitOps workflow.

## Why Automate with GitHub Actions?

**Continuous Deployment**: Automatically deploy infrastructure changes on push or pull request.

**Consistency**: Same deployment process every time, reducing human error.

**Audit Trail**: Every deployment is tracked in your git history.

**Collaboration**: Team members can trigger deployments through pull requests.

## Workflow Components

A typical GitHub Actions workflow for Ansible includes:

1. **Checkout Code**: Get your playbooks and inventory
2. **Setup Python/Ansible**: Install required dependencies
3. **Configure Secrets**: Inject credentials securely
4. **Run Playbook**: Execute Ansible against your infrastructure
5. **Report Results**: Notify team of success or failure

## Example Workflow

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Ansible
        run: |
          pip install ansible
          
      - name: Run Playbook
        env:
          ANSIBLE_HOST_KEY_CHECKING: False
        run: |
          ansible-playbook -i inventory playbook.yml
```

## Security Best Practices

**GitHub Secrets**: Store sensitive data like SSH keys and API tokens in GitHub Secrets.

**Environment Protection**: Use GitHub Environments for production deployments with required reviewers.

**Limited Scope**: Grant minimal permissions to your GitHub Actions workflows.

**Audit Logs**: Review deployment history regularly.

## Advanced Features

- **Matrix Builds**: Deploy to multiple environments in parallel
- **Conditional Deployment**: Deploy only when specific files change
- **Manual Approval**: Require approval for production changes
- **Status Checks**: Block deployments if tests fail

## Integration Benefits

Combining GitHub Actions with Ansible creates a powerful automation pipeline that's:
- Version controlled
- Reviewable
- Testable
- Auditable
- Repeatable

Read the full article on Medium: [How to run an Ansible playbook using GitHub Action](https://faun.pub/how-to-run-an-ansible-playbook-using-github-action-42430dec944)
