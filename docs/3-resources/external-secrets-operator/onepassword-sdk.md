---
type: resource
description: Deep dive into the native 1Password SDK provider in External Secrets Operator, comparing it with Connect server, and covering vault architecture, schema resolution, and zero-bridge deployment
related_resources:
  - external-secrets-operator
related_projects:
  - dark-k3s-stack
---

# 1Password SDK Provider for External Secrets Operator

## Overview

In modern Kubernetes environments, managing secrets with 1Password historically meant deploying the **1Password Connect Server**—a dual-container deployment (`connect-api` and `connect-sync`) requiring local persistent storage, periodic bridge syncs, and dedicated container maintenance.

With the release of External Secrets Operator (ESO) `v0.9.14+`, ESO introduced the **Native 1Password SDK Provider (`onepasswordSDK`)**. This provider compiles the official 1Password Go SDK directly into the ESO controller, connecting straight to the 1Password Cloud API using a 1Password Service Account.

---

## 1. Architectural Comparison: Connect Server vs Native SDK

| Dimension | Legacy: 1Password Connect Server | Modern: Native 1Password SDK (`onepasswordSDK`) |
| :--- | :--- | :--- |
| **Components** | 2 additional containers (`connect-api` + `connect-sync`) | **Zero extra containers** (in-process Go SDK inside ESO) |
| **Storage Requirement** | Requires PersistentVolume (`/home/opuser/.op/data`) for SQLite database | **Stateless** (ephemeral in-memory API queries) |
| **Authentication** | `1password-credentials.json` + `CONNECT_TOKEN` | Single **Service Account Token** (`Secret/onepassword-service-account`) |
| **Sync Latency** | Bridge polling sync delay + ESO reconciliation delay | Direct API query upon ESO refresh interval |
| **Maintenance** | Upgrade Connect container images, handle SQLite locks | Single HelmRelease for ESO controller |
| **Resource Overhead** | ~200MB RAM + ~100m CPU per cluster | **0MB additional overhead** |

---

## 2. Platform Bootstrap & ClusterSecretStore Configuration

The bootstrap architecture follows a strict "Single Injected Secret" pattern:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           BOOTSTRAP FLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. 1Password Service Account created in 1Password UI/CLI                   │
│    • Vault Access: Read permissions on vault 'infra-bootstrap-tools'        │
│    • Output: Service Account Token (ops_...)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ 2. Ansible (k3s_flux_bootstrap) injects single bootstrap Secret:           │
│    • Namespace: external-secrets                                            │
│    • Name: onepassword-service-account                                      │
│    • Key: token: ops_...                                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│ 3. Flux reconciles ClusterSecretStore/onepassword:                          │
│    • Provider: onepasswordSDK                                               │
│    • Vault: ${ONEPASSWORD_VAULT}                                            │
│    • auth.serviceAccountSecretRef: onepassword-service-account              │
├─────────────────────────────────────────────────────────────────────────────┤
│ 4. Any workload across any namespace uses ClusterSecretStore/onepassword    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Manifest Definition (`kubernetes/fleet/k3s/infra-addons/cluster-secret-store.yaml`)

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

---

## 3. Item & Field Mapping Conventions

In the 1Password SDK provider, values are resolved using either slash-concatenated keys or the explicit `property` field:

### A. Passwords and Standard Concealed Fields
When accessing a standard `LOGIN` or `API_CREDENTIAL` item:
```yaml
data:
  - secretKey: api-key
    remoteRef:
      key: KUBEOPENCODE_GOOGLE_API_KEY/password
```

### B. Fields Containing Spaces or Custom Labels
When targeting items with spaces in the field label (e.g., an `SSH_KEY` item with field `private key` or `App ID`):
```yaml
data:
  - secretKey: private-key.pem
    remoteRef:
      key: xnok-kubeopencode.2026-11-21.private-key
      property: private key
```

### C. Multi-line Strings and RSA PEM Keys
- 1Password stores multiline text cleanly in `notesPlain` or `SSHKEY` fields.
- The 1Password SDK preserves line breaks (`\n`) without requiring base64 pre-encoding.
- The receiving Kubernetes `Secret` receives standard UTF-8 text ready for mounting.

---

## 4. Best Practices & Security Rules

1. **Service Account Least Privilege**:
   - Limit the 1Password Service Account to read-only permissions on the specific cluster vault (`infra-bootstrap-tools`).
   - Do not grant access to personal vaults or unrelated infrastructure vaults.
2. **Refresh Intervals**:
   - Static API keys, database credentials, and certificates should use `refreshInterval: 1h`.
   - Avoid aggressive refresh intervals (<5m) to stay well within 1Password API rate limits.
3. **Cluster Portability**:
   - The vault name is parameterized via `${ONEPASSWORD_VAULT}`.
   - Any new cluster (e.g. `fleet/kind`, `fleet/k3s`, or a second edge server) only requires the Service Account token and vault variable to seamlessly reconstruct all application secrets.
