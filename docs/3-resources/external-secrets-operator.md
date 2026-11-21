---
type: resource
description: Kubernetes operator for synchronizing secrets from external secret management systems (1Password, AWS Secrets Manager, Vault, GitHub) into native Kubernetes Secrets
related_projects:
  - dark-k3s-stack
  - github-app-agent-integration
  - install-kubeopencode-k3s
related_areas:
  - security-identity
  - kubernetes-gitops
---

# External Secrets Operator (ESO)

## Overview

The **External Secrets Operator (ESO)** is a Kubernetes-native secrets synchronization engine that reads credentials from external APIs and secret management vaults (such as 1Password, AWS Secrets Manager, HashiCorp Vault, and GitHub Apps) and automatically transforms them into native Kubernetes `Secret` resources.

In the `infra-bootstrap-tools` architecture, ESO is the cornerstone of our **Zero-Secret GitOps** principle:
- **Git remains 100% clean**: Manifests declare *intent* (`ExternalSecret`, `ClusterSecretStore`) without containing passwords, tokens, or encryption keys.
- **One-time Bootstrap**: Ansible or the platform bootstrapper injects only a single bootstrap credential (the 1Password Service Account token). From that point forward, ESO autonomously reconciles and distributes all cluster secrets.
- **Dynamic Credentials**: Rather than distributing long-lived static tokens, ESO generates dynamic, short-lived tokens (such as 1-hour GitHub App access tokens) with automated background rotation.

---

## 1. Core Architecture & Custom Resource Definitions

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              ESO ARCHITECTURAL TOPOLOGY                                │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. BACKEND VAULT / IDENTITY PROVIDER                                                   │
│    • 1Password Vault (via 1Password SDK)                                               │
│    • GitHub API (via GitHub App JWT Exchange)                                          │
│    • HashiCorp Vault / Cloud Secret Managers                                           │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. PROVIDER SPECIFICATION (Infrastructure Plane)                                       │
│    • ClusterSecretStore: Cluster-wide access to backend provider (e.g. onepasswordSDK) │
│    • SecretStore: Namespaced access to backend provider                                │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. RECONCILIATION ENGINE (ESO Controller)                                              │
│    • ExternalSecret: Consumer intent specifying target Secret, refreshInterval, keys   │
│    • Custom Generators: Dynamic credentials (GithubAccessToken, VaultDynamicSecret)    │
│    • PushSecret: Outbound secret synchronization (Kubernetes -> External Vault)        │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ 4. CONSUMPTION (Workload Plane)                                                        │
│    • Standard Kubernetes Secret (core/v1)                                              │
│    • Consumed by Pods as env vars, volume mounts, or imagePullSecrets                  │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### The Key Custom Resources

| Custom Resource | Scope | Purpose | Best Used For |
| :--- | :--- | :--- | :--- |
| **`ClusterSecretStore`** | Cluster | Defines backend vault provider credentials globally across all namespaces. | Platform vault connections (e.g. `onepassword` SDK) shared across workloads. |
| **`SecretStore`** | Namespaced | Defines backend vault provider scoped strictly to a single namespace. | Strict multi-tenant teams with their own dedicated vaults. |
| **`ExternalSecret`** | Namespaced | Specifies which secrets to fetch, how to map/transform them, and target Kubernetes `Secret`. | Declaring workload credentials (API keys, TLS certs, database strings). |
| **`GithubAccessToken`** | Namespaced | Dynamic generator that exchanges GitHub App credentials for installation tokens. | Ephemeral CI/CD and AI agent repository access tokens. |
| **`PushSecret`** | Namespaced | Syncs Kubernetes-generated secrets back into external vaults. | Auto-generated database passwords or cert-manager TLS certs. |

---

## 2. Patterns & Best Practices Adopted in This Stack

### Pattern A: Native 1Password SDK Provider (`onepasswordSDK`)
Historically, integrating 1Password with Kubernetes required deploying the containerized **1Password Connect Server** sidecar, configuring persistent SQLite volume storage, and maintaining synchronization bridges.

In modern ESO (v0.9.14+), we adopt the native **1Password SDK (`onepasswordSDK`)**:
- **Zero Bridge Containers**: ESO connects directly to the 1Password Cloud API using the official Go 1Password SDK.
- **Single Bootstrap Secret**: Ansible provisions one secret (`Secret/onepassword-service-account` with key `token`) in the `external-secrets` namespace.
- **Universal Cluster Access**: A single `ClusterSecretStore/onepassword` services all workloads across the cluster:

```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: onepassword
spec:
  provider:
    onepasswordSDK:
      vault: "${ONEPASSWORD_VAULT}"
      auth:
        serviceAccountSecretRef:
          name: onepassword-service-account
          namespace: external-secrets
          key: token
```

### Pattern B: Dynamic GitHub App Access Tokens (`GithubAccessToken`)
Static Personal Access Tokens (PATs) suffer from major security liabilities: they are long-lived, tied to individual human user accounts, and broad in repository scope.

We adopt the **Dynamic GitHub App Generator**:
1. Store the GitHub App RSA Private Key in 1Password.
2. Synchronize the private key into Kubernetes using ESO `ClusterSecretStore/onepassword`.
3. Configure `GithubAccessToken` generator with App ID, Installation ID, and Private Key reference.
4. An `ExternalSecret` reconciles every 50 minutes, minting a fresh 1-hour GitHub installation token:

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
---
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

---

## 3. Multi-Tenancy & Security Hardening

### A. Preventing Cross-Namespace Credential Leakage
In multi-tenant clusters managed via Flux:
- Flux controllers enforce `--no-cross-namespace-refs=true`. A tenant in `tenant-cool-tool` cannot reference a `Secret` in `flux-system` or `external-secrets`.
- **The ESO Solution**: Rather than copying secrets manually, the platform envelope (templated by the Flux Operator `ResourceSet` factory) stamps out dedicated `ExternalSecret` objects in the tenant namespace that point to the platform's `ClusterSecretStore`.
- The Kubernetes `Secret` is owned exclusively by the tenant's `ExternalSecret` (`creationPolicy: Owner`).

### B. Creation Policies: Owner vs Orphan vs Merge
- **`Owner` (Recommended)**: The generated Kubernetes `Secret` has `ownerReferences` pointing to the `ExternalSecret`. If the `ExternalSecret` or tenant namespace is deleted, Kubernetes garbage collection automatically cleans up the secret.
- **`Orphan`**: Leaves the Kubernetes `Secret` behind if the `ExternalSecret` is deleted. Use with caution (risks stale credential leakage).
- **`Merge`**: Merges values into an existing secret without overwriting unmanaged keys.

---

## 4. Hard-Won Operational Lessons & Gotchas

### 1. 1Password Field Syntax & Type Variations
- **Concealed Passwords**: `remoteRef.key: ITEM_TITLE/password` or `remoteRef.key: ITEM_TITLE/credential`.
- **Labels with Spaces**: If a field is labeled `private key` or `App ID`, use the `property` field:
  ```yaml
  remoteRef:
    key: xnok-kubeopencode.2026-11-21.private-key
    property: private key
  ```
- **RSA Private Keys & Secure Notes**: In 1Password, multi-line PEM strings stored in `notesPlain` or `SSHKEY` fields preserve exact line breaks (`\n`). Verify that the target `secretKey` matches the application expectations (e.g. `private-key.pem`).

### 2. Tuning Refresh Intervals vs API Quotas
- Setting `refreshInterval` too aggressively (< 1m) can cause rate-limiting from external cloud APIs (e.g., 1Password, GitHub, AWS).
- **Static Vault Credentials**: Use `refreshInterval: 1h`.
- **Short-Lived Ephemeral Tokens**: For 1-hour GitHub tokens, set `refreshInterval: 50m` (10 minutes buffer before expiry).

### 3. Staged Garbage Collection in Multi-Tenant Environments
If a tenant namespace is deleted, deleting the `ExternalSecret` before workload pods terminate can cause pod crash loops. The Flux Operator `ResourceSet` solves this by staging garbage collection: child Flux Kustomizations are finalized and workloads removed *before* the tenant secrets and namespace are destroyed.

---

## 5. Troubleshooting & Diagnostics

### Check ExternalSecret Health
```bash
kubectl get externalsecrets -A
kubectl describe externalsecret <name> -n <namespace>
```
Look for `Status.Conditions`:
- `Type: Ready, Status: True`: Secret is successfully fetched and synced.
- `Type: Ready, Status: False, Reason: SecretSyncError`: Check event logs for invalid field names, permission errors, or expired credentials.

### Inspect Controller Logs
```bash
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets -f
```

---

## Subtopics & Deep Dives

- [1Password SDK Provider Architecture](external-secrets-operator/onepassword-sdk.md) — Comprehensive guide to native 1Password SDK, vault schemas, and zero-bridge deployment.
- [Dynamic GitHub Token Generator](external-secrets-operator/github-token-generator.md) — Blueprint for automated GitHub App installation token rotation and bot identity integration.
