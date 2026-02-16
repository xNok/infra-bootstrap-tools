# k3s_flux_bootstrap

## 1.0.1

### Patch Changes

- c6087dd: Updated OpenZiti and K3s "Dark" Setup:
  - **k3s_server**: Migrated from command-line arguments to `/etc/rancher/k3s/config.yaml` for configuration. Added support for binding API only to local interfaces (dark mode).
  - **k3s_flux_bootstrap**: Fixed `FluxInstance` spec to use `kind: OCIRepository` and added `path: "."` for OCI-based bootstrap.
  - **k3s_os_hardening**: Added UFW rules to restrict K3s API access to a specific CIDR and ensure secure defaults.
  - **ansible-collection**: General updates to coordinate the new roles and configuration.
