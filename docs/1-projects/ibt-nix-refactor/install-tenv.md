# Install Tenv via Nix

**Task**: The user requested that Nix be configured to install `tenv`.

## Plan
- Add `tenv` to `bin/nix/common.nix`.
- We will *not* add `terraform` directly, because the `tenv` Nix package provides its own shim binaries for `terraform`, `terragrunt`, `tofu`, and `atmos`. Having both installed alongside each other creates a `PATH` conflict, where the static Nix version of Terraform might shadow the one managed by `tenv` (or vice versa, resulting in unpredictable behavior depending on random PATH assignments when collisions are ignored).
- We also no longer need to whitelist `terraform` in `allowUnfreePredicate`, as `tenv` handles the downloading and execution dynamically via its shims.

## Implementation Details
Modify `bin/nix/common.nix`:
1.  Add `tenv` to the `basePackages`.
2.  Remove `terraform` from `basePackages`.
3.  Revert `allowUnfreePredicate` back to only `1password-cli`.
