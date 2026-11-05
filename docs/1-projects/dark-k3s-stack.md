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
  - Added rigorous, deep assertions to the local integration test suite (`bin/tests/flux-d2/test.sh`) to explicitly verify `cert-manager`, `trust-manager`, `ziti-controller`, `ziti-router-enroll` job completion, and `ziti-router` HelmRelease readiness, guaranteeing the cluster's dark overlay network works end-to-end.

- **Makefile Integration Test Target**:
  - Identified the need to simplify running integration tests locally.
  - Adding a `test-flux-d2` target to the `Makefile` to automate:
    1. Ensuring the local Kind cluster and container registry are active by executing `bin/k8s/setup-kind-local-registry.sh`.
    2. Running the full Flux D2/OpenZiti integration test suite via `bin/tests/flux-d2/test.sh`.

- **Live Server Audit & Status (Production Host)**:
  - **OS & Node Status**: Ubuntu 24.04.4 LTS, kernel 6.8.0-63-generic, uptime >475 days. K3s `v1.34.4+k3s1` is running and healthy as control-plane.
  - **Running Workloads**:
    - `cert-manager` (cert-manager, cainjector, webhook) & `trust-manager` running.
    - `flux-operator` (v0.62.1) and all standard Flux controllers running.
    - `openziti` controller and edge router running and connected.
    - Legacy Docker Swarm is active with a standalone `portainer_agent:2.33.1` container (worker node).
  - **GHCR PAT Resolved**:
    - Updated `GitHub_Flux_Token` in 1Password vault `infra-bootstrap-tools`.
    - Applied fresh credentials to `secret/flux-system` in `flux-system` namespace on the cluster.
    - Both `OCIRepository/flux-system` and `OCIRepository/infra-addons` reconciled successfully (`READY: True`).
    - Kustomizations `flux-system` and `infra-addons` successfully applied the latest OCI artifacts.
- **OpenZiti Stack Configuration & External Ingress (Resolved)**:
  - Controller client API configured to advertise on `${ROUTER_ADVERTISED_HOST}:1280`.
  - Cert-manager patch injected into Kustomization `1-kustomize.yaml` adding `${ROUTER_ADVERTISED_HOST}` to `openziti-ziti-controller-web-identity-cert` IP SANs, resolving Go x509 IP verification panics.
  - Router configured with `edge.advertisedHost: "${ROUTER_ADVERTISED_HOST}"`, `edge.advertisedPort: 8442`, LoadBalancer service, and `csr.sans.ip: ["${ROUTER_ADVERTISED_HOST}"]`.
  - Re-enrolled `ziti-router` cleanly with IP SAN in certificate; router is healthy, 1/1 Running, and `isOnline: true`.
  - Configured OpenZiti zero-trust overlay service `k3s` (intercepting `k3s.ziti:443` -> `kubernetes.default.svc:443`) with bind policy for `@ziti-router` and dial policy for `#k3s-clients`.
  - Created client identities `mobile-client` and `laptop-client` with role attribute `#k3s-clients` and generated single-use enrollment tokens/QR codes.
  - Ports 1280 (OpenZiti Controller Client API) and 8442 (OpenZiti Router Edge) opened in UFW; direct Kubernetes port 6443 blocked from public internet.

## Current State
- [Completed] Refactored `k3s_server` to use `config.yaml`.
- [Completed] Fixed Flux OCI bootstrap resource kind.
- [Completed] Implemented initial UFW rules in `k3s_os_hardening`.
- [Completed] Fixed path mismatch in `flux-instance.yaml.j2`.
- [Completed] Added `infra-addons` OCI publishing on push to `main` in GitHub Actions workflow.
- [Completed] Refactored and aligned `kind` and `k3s` infra-addons layouts.
- [Completed] Verified live host status: control-plane node up, OpenZiti and Flux running.
- [Completed] Unblocked Flux OCI sync with updated GitHub PAT from 1Password (`flux-system` & `infra-addons` OCI sources are healthy and reconciled).
- [Completed] Configured OpenZiti external ingress and IP SANs via dynamic `${ROUTER_ADVERTISED_HOST}` substitution without committing public IPs.
- [Completed] Verified zero-trust `k3s` service routing and generated mobile/laptop enrollment credentials.
- [Completed] Opened draft Pull Request [#234](https://github.com/xNok/infra-bootstrap-tools/pull/234) with CI pipeline checks running.
- [Completed] Fixed Keycloak security red flag: replaced plaintext admin credentials with `secretKeyRef` pointing to `keycloak-admin-credentials`, and added bootstrap secrets step in `test.sh`.
- [Completed] Sanitized `ziti-realm.json`: removed hardcoded dummy test user with plaintext password and removed unused dummy client secret.
- [Completed] Fixed `reconcile.fluxcd.io/watch` bug: switched from `annotations:` to `labels:` in `generatorOptions` across all kustomizations.
- [Completed] Reorganized `infra-addons` component layouts: segregated non-K8s resources into `scripts/`, `values/`, and `data/` subdirectories.
- [Completed] Decoupled controllers and configurations across `infra-addons`: consolidated generic automation jobs inside `components/openziti` with secure-by-default `ClusterIP` baselines, moved test realm config to `fleet/kind`, and enabled overlay-free fleet configuration.
- [Completed] Validated consolidated architecture in Kind CI test suite (Test Flux Bootstrap run #41533551349 passed in 8m 36s).
- [Completed] Added Changeset tracking (`.changeset/k3s-openziti-zero-trust.md`) for releases across `kubernetes-infra-addons`, `ansible-collection-infra-bootstrap-tools`, `ansible-role-k3s-flux-bootstrap`, `ansible-role-k3s-os-hardening`, and `ansible-role-k3s-server`.
- [Completed] PR #234 merged into `main` and released via Changesets.
- [Completed] Reconciled and synced live K3s cluster with latest published OCI artifacts (`flux-system` and `infra-addons`).
- [Completed] Verified healthy cluster state: all HelmReleases `Ready: True`, controller and router 1/1 Running with external IP SANs, and zero-trust `k3s` service terminator established.
- [Completed] Generated fresh client enrollment credentials (`laptop-client.jwt`, `mobile-client.jwt`) and updated mobile QR code.
- [Completed] Packaged and installed `kubeztl` (zitified kubectl) in repository Nix configuration (`bin/nix/common.nix`, `flake.nix`):
  - Fixed OpenZiti Go SDK nil-pointer dereference in `cacheSession` against modern OpenZiti v1.7.2 controllers (`session.Service.ID` -> `*session.ServiceID`).
  - Added smart default identity and service detection (`~/.ziti/laptop-client.json` and service `k3s`, with `ZCONFIG` and `ZITI_SERVICE` override support).
  - Bundled in `ibt-flux` / `common.packages` and installed directly into active Nix profile (`nix profile add .#kubeztl`).
  - Verified daemonless zero-trust cluster queries directly from PATH (`kubeztl get nodes`, `kubeztl get pods -A`).
- [Completed] Resolved Flux reconciliation substitution bug for K3s OpenZiti stack:
  - Migrated cluster-specific host/IP overrides and cert-manager IP SAN patches from static ConfigMap generators into `Kustomization/infra-addons` (`1-kustomize.yaml`) using `HelmRelease` inline values and `postRenderers`.
  - Removed un-substituted `k3s-ziti-*-values` configMapGenerators to ensure automated GitOps reconciliations never overwrite cluster parameters.
  - Used JSON6902 `op: add` on `/spec/ipAddresses` for cert-manager IP SAN persistence and strict `--replace-fail` patching in Nix `kubeztl`.
- [Completed] Exposed Flux Operator Web UI (`flux-ui`) as a Zero-Trust Dark Service:
  - Discovered and utilized the built-in Web UI / Status dashboard in `flux-operator` (listening on port 9080), avoiding redundant external dashboards.
  - Resolved Go x509 SAN IP validation requirement (`Certificate.spec.ipAddresses`) and OpenZiti `os.ExpandEnv` host string evaluations.
  - Provisioned OpenZiti dark service `flux-ui`:
    - Intercept config: `flux.ziti:80` and `flux.ziti:9080`.
    - Host config: `flux-operator.flux-system.svc.cluster.local:9080`.
    - Bound terminator to `@ziti-router` and granted dial access to `#k3s-clients`.
  - Verified end-to-end zero-trust HTTP 200 OK access using OpenZiti Go SDK and confirmed readiness for mobile phone browsing via Ziti Mobile Edge at `http://flux.ziti`.
- [Completed] Modularized `kubeztl` into a standalone Nix package (`bin/nix/pkgs/kubeztl.nix`) imported via `pkgs.callPackage` in `bin/nix/common.nix`, aligning with Nixpkgs packaging standards (`pkgs/by-name/ku/kubeztl/package.nix`) for upstream reuse or contribution.
- [Completed] Documented comprehensive client access architecture in [docs/1-projects/dark-k3s-stack/client-access.md](dark-k3s-stack/client-access.md): dropped ad-hoc userspace port-forwarding helpers in favor of native OS-level transparent tunnelers (`ziti-edge-tunnel` via system systemd on Linux, `Ziti Mobile Edge` on mobile), explaining why Home Manager should not manage kernel TUN devices and providing full setup instructions.
- [Completed] Restored decoupled "AWS Addon" architecture documented in [docs/1-projects/dark-k3s-stack/addon-architecture.md](dark-k3s-stack/addon-architecture.md): eliminated all 59 lines of inline RFC 6902 Kustomize patches in `fleet/k3s/infra-addons/1-kustomize.yaml` and all `postRenderers` in `infra-addons/components/openziti/controller.yaml` by transitioning from raw IP addresses to a DNS hostname (`ziti.nokwebspace.ovh`).
- [Completed] Formulated DNS management & bare-metal LoadBalancer strategy documented in [docs/1-projects/dark-k3s-stack/dns-and-loadbalancing.md](dark-k3s-stack/dns-and-loadbalancing.md): clarified cert-manager vs external-dns vs Ansible roles, established Ansible bootstrap automation for DigitalOcean DNS, and defined on-prem multi-node LB roadmap (Klipper -> MetalLB / Kube-VIP).
- [Pending] SSH Zitification & legacy Swarm / Portainer agent cleanup.




