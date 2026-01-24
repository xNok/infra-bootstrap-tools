---
title: "Speedup Ansible Playbook Pull-Requests by Running Only Affected Roles"
date: 2023-10-15
author: xNok
summary: Learn how to optimize your Ansible CI/CD pipeline by detecting and running only the roles that changed in a pull request.
canonical_url: https://medium.com/itnext/speedup-ansible-playbook-merge-request-by-only-running-affected-roles-42d9ca3f6433
tags:
  - Ansible
  - CI/CD
  - Optimization
  - GitHub Actions
  - DevOps
---

# Speedup Ansible Playbook Pull-Requests by Running Only Affected Roles

When working with large Ansible projects, running the entire playbook for every pull request can be time-consuming and wasteful. Learn how to detect changed roles and run only what's necessary.

## The Problem

As your infrastructure grows, your Ansible playbooks become larger and more complex. Running everything on every commit:
- Wastes CI/CD minutes
- Slows down development feedback
- Increases costs
- Delays deployments

## The Solution

Implement smart change detection to identify which roles were modified and run only those roles during PR validation.

## How It Works

1. **Detect Changes**: Compare the current branch with the base branch
2. **Identify Affected Roles**: Parse git diff to find modified role directories
3. **Generate Dynamic Playbook**: Create a playbook that includes only changed roles
4. **Run Targeted Tests**: Execute Ansible against the subset
5. **Report Results**: Provide feedback on the PR

## Implementation Strategy

### Step 1: Detect Changed Files

```bash
git diff --name-only origin/main...HEAD | grep '^ansible/roles/'
```

### Step 2: Extract Role Names

Parse the file paths to determine which roles were affected.

### Step 3: Create Dynamic Playbook

Generate a temporary playbook that includes only the modified roles:

```yaml
- hosts: all
  roles:
    - role: changed_role_1
    - role: changed_role_2
```

### Step 4: Integrate with CI/CD

Add this logic to your GitHub Actions or GitLab CI pipeline.

## Benefits

**Faster Feedback**: PRs complete in minutes instead of hours.

**Cost Reduction**: Use fewer CI/CD minutes.

**Parallel Execution**: Run multiple small tests simultaneously.

**Better Developer Experience**: Quick iterations encourage better practices.

## Considerations

- **Dependencies**: Handle role dependencies correctly
- **Integration Tests**: Some changes may require full playbook runs
- **Shared Resources**: Consider roles that interact with shared infrastructure

## Real-World Results

In our project:
- **80% faster**: Most PRs now complete in under 5 minutes
- **Cost savings**: Reduced CI costs by 70%
- **Higher quality**: Developers iterate more frequently

This optimization is particularly valuable for monorepo setups where multiple roles coexist.

Read the full article on Medium: [Speedup Ansible Playbook Pull-Requests](https://medium.com/itnext/speedup-ansible-playbook-merge-request-by-only-running-affected-roles-42d9ca3f6433)
