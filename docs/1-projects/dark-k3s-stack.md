# Dark K3s Stack Implementation Plan

## Goal
Implement a "Dark" K3s stack where the API server is bound to localhost and exposed only via OpenZiti.
Use FluxCD for GitOps, bootstrapped via Ansible using credentials from 1Password.

## Architecture
- **Infrastructure**: Ansible roles for Ubuntu/Debian.
- **Control Plane**: K3s bound to 127.0.0.1.
- **Networking**: OpenZiti (Controller in-cluster, Router as a pod).
- **GitOps**: FluxCD (GitHub as source of truth).
- **Secrets**: 1Password (Ansible lookup).

## Implementation Steps

### Phase 1: Ansible Bootstrap
1.  **OS & Firewall Hardening**:
    - Role to configure UFW.
    - Open: 8441 (Ziti Controller), 8442 (Ziti Edge Router), 22 (SSH - temporary).
    - Close: 6443 (K3s API) from public interface.
2.  **K3s Installation**:
    - Install K3s with `INSTALL_K3S_EXEC="--tls-san k3s.ziti --bind-address 127.0.0.1 --disable traefik"`.
3.  **Flux Bootstrap**:
    - Retrieve GitHub PAT from 1Password.
    - Run `flux bootstrap github`.

### Phase 2: GitOps Configuration (Later)
- Configure OpenZiti Controller and Router via Flux.
- Set up Ziti tunnel for API access.

### Phase 3: Secure Device Enrollment (Later)
- Enroll devices into Ziti network.
- Setup RBAC/CSR for kubectl access.

### Phase 4: Final Lockdown (Later)
- Zitify SSH.
- Close port 22 on public firewall.

## Notes & Findings
- **Flux OCI Bootstrap**:
  - The `FluxInstance` CRD resource `kind` must be `OCIRepository`, not `OCIArtifact`, for OCI-based bootstrap.
  - The `path: .` field is required in the spec when bootstrapping from the root of the repo/artifact.
  - Verification: `flux get sources oci` and `flux get kustomizations`.

- **K3s Configuration**:
  - Moved from command-line arguments in systemd service to `/etc/rancher/k3s/config.yaml`.
  - This allows easier updates and cleaner systemd units.
  - Legacy arguments (`--bind-address`, etc.) in `k3s.service` will trigger a one-time re-install to migrate to config file.
  - Added `k3s_server_use_openziti_dark` flag to control binding to `127.0.0.1` vs `0.0.0.0`.

- **OS Hardening**:
  - `k3s_os_hardening` role now manages UFW.
  - Defaults to deny incoming, allow outgoing.
  - SSH (22) is allowed temporarily but constrained by source IP if configured.
  - K3s API (6443) access is restricted to `k3s_os_hardening_k3s_api_cidr`.

- **GHCR OCI Pull Credentials**:
  - Private OCI packages on `ghcr.io` require standard OCI pull secrets (`secretRef`).
  - Added `secretRef: name: flux-system` to the `infra-addons` OCIRepository in `kubernetes/fleet/k3s/oci-sources.yaml` (subsequently refactored into `infra-addons/0-install.yaml`).
  - Identified that the `flux-system` pull secret is created by the Ansible `k3s_flux_bootstrap` role using 1Password's `GitHub_Flux_Token`.
  - Added OCI publishing step for `infra-addons` to `.github/workflows/flux-oci-publish.yml` so that every push to `main` automatically publishes updated addons alongside fleet configurations.

- **OCI Sync Path Mismatch (CI vs. Ansible)**:
  - Discovered a mismatch where the CI/CD pipeline publishes `./kubernetes/fleet/k3s` at the root (`.`) of the OCI artifact, but `flux-instance.yaml.j2` was configured with `path: "./fleet/k3s"`.
  - Fixed `ansible/roles/k3s_flux_bootstrap/templates/flux-instance.yaml.j2` to use `path: "."`, matching the checked-in configs and CI behavior.

- **Infra Addons Installation Refactoring & Alignment**:
  - Aligned `kubernetes/fleet/kind` with the user's refactored `infra-addons` directory design.
  - Organized `infra-addons/` directory by splitting the install manifest into `0-source.yaml` (`OCIRepository`) and `1-kustomize.yaml` (`Kustomization`) to separate intent.
  - Grouped all `.values.yaml` environment variables into a neat `values/` subdirectory, keeping the root of `infra-addons` completely free of variable/value clutter.
  - Cleaned up obsolete files and `infra-addons-values/` directory in `kind` and `k3s`.

## Current State
- Investigating existing Ansible roles and playbooks.
- [Completed] Refactored `k3s_server` to use `config.yaml`.
- [Completed] Fixed Flux OCI bootstrap resource kind.
- [Completed] Implemented initial UFW rules in `k3s_os_hardening`.
- [Completed] Fixed path mismatch in `flux-instance.yaml.j2` (changed `path: "./fleet/k3s"` to `path: "."`).
- [Completed] Added `infra-addons` OCI publishing on push to `main` in GitHub Actions workflow.
- [Completed] Refactored and aligned `kind` and `k3s` infra-addons layouts with a nested `values/` directory and split installer resources.
- [Completed] Verified integration test suite compatibility (fully compatible with no changes needed).
