---
title: "Intentional Releases: Why We Chose Changesets over Semantic-Release"
date: 2026-04-12
author: xNok
summary: Automated releases are great, but they often lack human intent. Learn why Changesets is the better tool for managing releases in a complex monorepo.
tags:
  - DevOps
  - Changesets
  - CI/CD
  - Release Management
  - Open Source
---

# Intentional Releases: Why Chose Changesets over Semantic-Release

In the world of DevOps, sometime maybe we automate a little bit too much. We aim for a smooth and continous deployment process where we automate builds ,testing, we automate deployment, and we automate versioning. The gold standard is probably tools like `semantic-release` utilities that parse your git history, look for keywords like "feat" or "fix" prefixes, and automatically bump versions and generate changelogs (this is called semantic release by conventional commit).

It sounds perfect, and the promice is genious, make small intentianl commits with clear description such that you don't need to waste time writing a changelog latter. WHile the idea is sound the chnagelogs produce with this workflow are rarely up to the expectation of the end users.

When more often that not endup with a long list of commit messages that so not convait the essence of a release just an agglomeration of small change, letting me wondering what is the point of this release at all, if anything notable really changes and if anuthing is really make this release worth upgating to other than doing some due diligence.

Overtime I think O have groun fed of if this standiard release not process and much prefered the teams that took the time to intentinnally cutting release rather than aiming to an automatiing unemotional release process.

When working on Backstage, I was introduced to Changesets, and I reallise the the node ecostystem especially those deleasing with large monorepo had felt the need for better intentinal release process. So i set mysefl on the quest of integrating Changesets into any monore rpos especiall infra-bootstrap-tools which contain absolutly non nodejs code, you would find some Python modeles, Ansible Collections, Terrofram docules and docker-compose configureation all my experiment that i thrived the package and versionned in a reasonable way avoiding the automated semantic-release process.

## The semantic-release and conventianl commits

Before we get started it might be worth clear a common confusion arround Sementic versioning and semantic-release.

Semantic versioning is a versioning scheme that is used to version software. It is a way to communicate the changes in a software to the users while semantic-release is a nodejs base cli tool that implement generate semantic versioning based on the conventianl commit specification.

So we can have semantic versioning and "release" said version without conventinal commit, but the poluar tool semantic-release implement the conventianl commit specification.

I don't like this naming for the tools (semtnic-release) because to me as long as my release is using semantic versionning it should be a semantic release regardless of weither i use comventinal commit or not, but due to the polularity of semantic-release people pretty much unilateraly assume that semantic release meant using the conventianl commit specification.

Here we are still striving to use semantic versioning menaing that each version number is compose ov a troples x.y.z where x is the major version, y is the minor version and z is the patch version. Each of those number refrecting the divergence of the codebase from the previous version. for instance:
- x is the major version, and it is incremented when we make breaking changes, meaning this version is not backward compatible with the previous version
- y is the minor version, and it is incremented when we add new features, but it is backward compatible with the previous version
- z is the patch version, and it is incremented when we fix bugs, but it is backward compatible with the previous version and no new features are introduced.


## The Problem with Commit-Based Automation

Commit messages are primarily by developer for developer, after all we would mostly conncern ourself about comit mesage on pull request and git history, But any code change is often more that the implementation detail of a simgle change and a collection of commit can yiel to a feature more comprehensive and complet tha the sum of the cheanges. This describing a release based on what as change is definitly not always the best way to communicate the value of a release to the end users.

When you force your release notes to be a direct reflection of your commit history, you run into two major issues:

1.  **The Noise Factor**: A single "feature" might involve five "feat" commits and dozens of "fix" commits. Your changelog becomes a cluttered list of technical steps rather than a summary of value.

2.  **The Intent Gap**: A developer might fix a bug that technically requires a patch bump, but they realize this change actually signals a pivot in how the tool should be used. Commit parsers can't capture that nuance.

While you could technically improve the release description after the release has been cut and a commit has been tg with a semantic version, it is often not done and the release notes remain a cluttered list of technical steps rather than a summary of value.

Finally I am not saying that semantic commit are a bad ideal, actually i thing is is a great thing to ask developer and ai a alike to think about the impact of their change and communicate it clearly, but it should not be the only source of truth for release notes.

## Changesets: Forcing Developer Intent in release process

Changesets takes a different approach. Instead of guessing what should be released based on your commits, it asks you—the developer—to explicitly state your intent.

When you finish a task, you run `npx changeset add`. You are then prompted to:
1.  **Select the affected packages**: In a monorepo like infra-bootstrap-tools, this is important because we could have multiple packages that are released together.
2.  **Choose the bump type**: Major, minor, or patch.
3.  **Write the summary**: A human-readable description of the change.

This small markdown file stays in your branch, goes through peer review, and sits in the `.changeset/` folder until you are ready to release.

## Why "Intent" Matters for Your Users

The most powerful part of the Changeset workflow isn't the automation; it's the **pause**. Expecially in Pull request i love that the Bot is able to comment, this PR doen't have a Vhangeset yet. Meaning once this PR is complete please take the time to review the work and comme up with a description of what has change, an intentinal after the fact of what has changed.

When you write a changeset, you aren't just describing code (thechnically you should already be done with the implementation) you are communicating with your user base. You are saying: *"I have made this change, I believe it warrants a new version, and here is how it affects you."*

This process forces a level of quality that "automated" commit parsing simply can't match:
- **Migration Guides**: You can explain *how* to upgrade from a breaking change right in the changeset.
- **Value Proposition**: You can explain *why* a new feature is exciting.
- **Explicit Versioning**: You avoid accidental major bumps caused by a mislabeled commit.

## Scaling to a Polyglot Monorepo

Changest would be a staitght forard adoption of nodejs users in a manarepo manages with npm, yarn, pnpm or (any future package manager that would come up), but for other user using changes might not event cross you mind. So let me give you a quick overview of how I use it in my `infra-bootstrap-tools` repository.

In `infra-bootstrap-tools` I manage all my self-hosted POCs and tools in a single monorepo, with a diverse set of technologies:
- **Ansible Collections** (YAML)
- **Python Packages** (Python/Agentic)
- **Docker Stacks** (YAML/Shell)

Changesets allows me to manage these disparate ecosystems with a single, unified workflow. Whether it's my Ansible Galaxi Collection or Terraform module or event some of my  recent Python agent experiments, the process is the same. 

I aim to gather these "intents" throughout the development cycle, and when the time is right, a single "Version Packages" PR merges them all into their respective `CHANGELOG.md` files, creates the release tags and trigger the respective publishing pipeleine the the artefact endup in the respective registry (Ansible Galaxi, PyPI, Docker Hub, etc).

### Deep Dive into the Workflow



## Conclusion: Choose Intent over Side-Effects

Automation should be a tool that assists the human, not a process that replaces them. By choosing Changesets over pure commit-parsing, we've made our release process more deliberate, our changelogs more readable, and our user communication more effective.

If you find that your automated releases feel like a "side-effect" of your coding rather than a "delivery" to your users, it might be time to put intent back into your workflow with Changesets.
