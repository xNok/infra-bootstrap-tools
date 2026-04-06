#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/../../.." && pwd)

CLUSTER_NAME=${CLUSTER_NAME:-"kind"}
SOURCE_URL=${SOURCE_URL:-"https://github.com/xNok/infra-bootstrap-tools"}
REVISION=${REVISION:-"local"}
FLEET_NAME=${FLEET_NAME:-"kind"}
REGISTRY_NAME=${REGISTRY_NAME:-"kind-registry"}
REGISTRY_PORT=${REGISTRY_PORT:-"5000"}

# --- colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}==>${RESET} $*"; }
success() { echo -e "${GREEN}${BOLD}  ✔${RESET}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}  ⚠${RESET}  $*" >&2; }
error()   { echo -e "${RED}${BOLD}  ✖${RESET}  $*" >&2; }

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "Missing required command: $cmd"
    exit 1
  fi
}

require_docker() {
  if docker info >/dev/null 2>&1; then
    return
  fi

  error "Docker is required for the Flux D2 integration test."
  cat >&2 <<'EOF'

If you are running in GitHub Codespaces, reopen the repository in the provided
devcontainer so Docker-outside-of-Docker is enabled, then enter the Flux shell:
  nix develop .#flux
EOF
  exit 1
}

dump_debug_state() {
  warn "Dumping Operator logs in case of failure..."
  kubectl logs -n flux-system -l app.kubernetes.io/name=flux-operator || true
  kubectl get fluxinstance flux -n flux-system -o yaml || true
}

for cmd in docker kubectl helm flux; do
  need_cmd "$cmd"
done

require_docker
trap dump_debug_state ERR

require_resource() {
  local resource="$1"
  local namespace="$2"
  info "Checking resource exists: ${BOLD}${resource}${RESET}${CYAN} (ns=${namespace})"
  kubectl get "${resource}" -n "${namespace}" > /dev/null
  success "Resource found: ${resource}"
}

wait_ready() {
  local resource="$1"
  local namespace="$2"
  local timeout="$3"
  info "Waiting for readiness: ${BOLD}${resource}${RESET}${CYAN} (ns=${namespace}, timeout=${timeout})"
  if ! kubectl wait --for=condition=ready "${resource}" -n "${namespace}" --timeout="${timeout}"; then
    echo "=== DEBUG LOGS ==="
    kubectl get events -n flux-system
    kubectl get fluxinstances -n flux-system -o yaml || true

    echo "ERROR: Timed out waiting for ${resource} in ${namespace}"
    kubectl describe fluxinstances -n flux-system
    kubectl describe ocirepository -n flux-system
    kubectl get kustomization -n flux-system -o yaml
    kubectl logs -n flux-system -l app.kubernetes.io/name=flux-operator
    exit 1
  fi
  success "Ready: ${resource}"
}

info "Installing Flux Operator via Helm..."
helm upgrade --install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system --create-namespace
success "Flux Operator installed."

info "Waiting for Flux Operator to become ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=flux-operator -n flux-system --timeout=2m
success "Flux Operator is ready."

info "Pushing the local kubernetes/ folder as an OCI artifact to the local registry..."
flux push artifact "oci://localhost:${REGISTRY_PORT}/flux-system:latest" \
  --path="${ROOT_DIR}/kubernetes/fleet/${FLEET_NAME}" \
  --source="${SOURCE_URL}" \
  --revision="${REVISION}"
success "Fleet OCI artifact pushed."

info "Pushing infra-addons/ as a separate OCI artifact to the local registry..."
flux push artifact "oci://localhost:${REGISTRY_PORT}/infra-addons:latest" \
  --path="${ROOT_DIR}/kubernetes/infra-addons" \
  --source="${SOURCE_URL}" \
  --revision="${REVISION}"
success "infra-addons OCI artifact pushed."

info "Validating local Kustomize entrypoints..."
kubectl kustomize "${ROOT_DIR}/kubernetes/fleet/${FLEET_NAME}" > /dev/null
kubectl kustomize "${ROOT_DIR}/kubernetes/infra-addons" > /dev/null
success "Kustomize entrypoints valid."

info "Bootstrapping cluster from OCI..."
kubectl apply -f "${ROOT_DIR}/kubernetes/fleet/${FLEET_NAME}/flux-system/flux-instance.yaml"
success "FluxInstance applied."

wait_ready "fluxinstance/flux" "flux-system" "2m"
wait_ready "ocirepository/flux-system" "flux-system" "1m"
wait_ready "kustomization/flux-system" "flux-system" "2m"

info "Waiting for infra-addons Kustomization to become ready..."
wait_ready "kustomization/infra-addons" "flux-system" "5m"

echo -e "\n${GREEN}${BOLD}  ✔  Flux D2 bootstrap test completed successfully!${RESET}\n"