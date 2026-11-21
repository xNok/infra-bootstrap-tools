---
type: resource
description: Architectural blueprint and operational guide for ESO's GithubAccessToken generator, automating dynamic GitHub App installation token rotation and bot identity integration
related_resources:
  - external-secrets-operator
related_projects:
  - github-app-agent-integration
---

# Dynamic GitHub App Token Generator (`GithubAccessToken`)

## Overview

In CI/CD pipelines, GitOps sync loops, and autonomous AI agent platforms (like KubeOpenCode), workloads must authenticate against GitHub to clone code, push branches, and open pull requests. 

Historically, platforms relied on **Personal Access Tokens (PATs)**. However, PATs present severe governance and security hazards:
1. **Coupled to Human Identities**: If the person leaves the team, tokens break.
2. **Excessive Lifetime**: PATs typically live for months or years without rotation.
3. **Broad Blast Radius**: PATs grant account-wide access across repositories.

The **External Secrets Operator `GithubAccessToken` generator** (`generators.external-secrets.io/v1alpha1`) solves this by generating **ephemeral, repository-scoped installation tokens** valid for 1 hour, continuously refreshed in the background.

---

## 1. How the Dynamic Generator Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       GITHUB TOKEN GENERATION FLOW                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. PREREQUISITES IN CLUSTER                                                 │
│    • App ID: "5866072" (configured in generator spec)                       │
│    • Installation ID: "184455973" (configured in generator spec)            │
│    • Private Key: Secret/github-app-private-key (synced from 1Password)     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 2. TOKEN MINTING (ESO Controller)                                           │
│    • Generates short-lived RSA-256 JWT using Private Key & App ID           │
│    • Calls GitHub API: POST /app/installations/{installId}/access_tokens     │
│    • Receives: installation access token (ghs_...) valid for 60 minutes     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 3. SECRET TARGETING & ROTATION                                              │
│    • ExternalSecret triggers reconciliation every 50 minutes                │
│    • Generates fresh token 10 minutes before expiration                     │
│    • Updates Kubernetes Secret/github-creds (key: token)                    │
├─────────────────────────────────────────────────────────────────────────────┤
│ 4. AGENT POD INGESTION                                                      │
│    • Mounted as GITHUB_TOKEN environment variable into running containers   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Manifest Specifications

### The Generator Resource (`generators.external-secrets.io/v1alpha1`)

```yaml
apiVersion: generators.external-secrets.io/v1alpha1
kind: GithubAccessToken
metadata:
  name: github-app-token-generator
  namespace: tenant-infra-bootstrap-tools
spec:
  appID: "5866072"
  installID: "184455973"
  url: https://api.github.com
  auth:
    privateKey:
      secretRef:
        name: github-app-private-key
        key: private-key.pem
```

### The Consumer ExternalSecret Resource (`external-secrets.io/v1beta1`)

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: github-creds
  namespace: tenant-infra-bootstrap-tools
spec:
  refreshInterval: 50m
  target:
    name: github-creds
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        token: "{{ .token }}"
  dataFrom:
    - sourceRef:
        generatorRef:
          apiVersion: generators.external-secrets.io/v1alpha1
          kind: GithubAccessToken
          name: github-app-token-generator
```

---

## 3. Pairing with Bot Committer Identity

When an agent pod commits files or pushes branches using an installation token (`ghs_...`), GitHub validates the token against the GitHub App. 

To display the verified **`bot`** badge and link commits back to the GitHub App profile, Git environment variables in the pod must follow the official GitHub user format:

```yaml
podSpec:
  env:
    - name: GIT_AUTHOR_NAME
      value: "xnok-kubeopencode[bot]"
    - name: GIT_AUTHOR_EMAIL
      value: "5866072+xnok-kubeopencode[bot]@users.noreply.github.com"
    - name: GIT_COMMITTER_NAME
      value: "xnok-kubeopencode[bot]"
    - name: GIT_COMMITTER_EMAIL
      value: "5866072+xnok-kubeopencode[bot]@users.noreply.github.com"
```

Formula: `<app-id>+<app-slug>[bot]@users.noreply.github.com`

---

## 4. Key Operational Rules & Gotchas

1. **50-Minute Refresh Cycle**:
   - GitHub installation tokens expire after 3600 seconds (1 hour).
   - Setting `refreshInterval: 50m` guarantees a 10-minute renewal overlap, preventing token expiration during long-running agent tasks.
2. **Template Engine v2**:
   - Always specify `template.engineVersion: v2`.
   - The generator exports `.token`. Using `token: "{{ .token }}"` maps the raw token string directly to the target Secret key.
3. **Repository Permissions**:
   - The token inherits whatever permissions were configured on the GitHub App at creation time.
   - For agent operations, required permissions are:
     - `contents: write` (cloning, branching, pushing)
     - `pull_requests: write` (opening and editing PRs)
     - `issues: write` (reading tasks and commenting)
     - `workflows: write` (modifying `.github/workflows/`)
     - `metadata: read` (repository info)
