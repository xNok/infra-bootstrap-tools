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
    kubectl describe "${resource}" -n "${namespace}" || true
    kubectl get pods -A || true
    kubectl get helmrelease -n "${namespace}" || true
    kubectl describe fluxinstances -n flux-system
    kubectl describe ocirepository -n flux-system
    kubectl get kustomization -n flux-system -o yaml
    kubectl logs -n flux-system -l app.kubernetes.io/name=flux-operator
    exit 1
  fi
  success "Ready: ${resource}"
}

# --- Phase Functions ---

require_dependencies() {
  info "Checking dependency commands..."
  for cmd in docker kubectl helm flux; do
    need_cmd "$cmd"
  done
  require_docker
  trap dump_debug_state ERR
}

install_flux_operator() {
  info "Installing Flux Operator via Helm..."
  helm upgrade --install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
    --namespace flux-system --create-namespace
  success "Flux Operator installed."

  info "Waiting for Flux Operator to become ready..."
  kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=flux-operator -n flux-system --timeout=2m
  success "Flux Operator is ready."
}

publish_oci_artifacts() {
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
}

validate_kustomize() {
  info "Validating local Kustomize entrypoints..."
  kubectl kustomize "${ROOT_DIR}/kubernetes/fleet/${FLEET_NAME}" > /dev/null
  kubectl kustomize "${ROOT_DIR}/kubernetes/infra-addons" > /dev/null
  success "Kustomize entrypoints valid."
}

bootstrap_test_secrets() {
  info "Provisioning bootstrap test secrets for Kind..."
  kubectl create namespace keycloak --dry-run=client -o yaml | kubectl apply -f -
  kubectl create secret generic keycloak-admin-credentials \
    -n keycloak \
    --from-literal=username=admin \
    --from-literal=password="admin_test_password" \
    --dry-run=client -o yaml | kubectl apply -f -
  success "Bootstrap test secrets provisioned."
}

bootstrap_flux() {
  bootstrap_test_secrets
  info "Bootstrapping cluster from OCI..."
  kubectl apply -f "${ROOT_DIR}/kubernetes/fleet/${FLEET_NAME}/flux-system/flux-instance.yaml"
  success "FluxInstance applied."

  wait_ready "fluxinstance/flux" "flux-system" "2m"
  wait_ready "ocirepository/flux-system" "flux-system" "1m"

  info "Forcing reconciliation of flux-system source and kustomization..."
  flux reconcile source oci flux-system || true
  flux reconcile kustomization flux-system || true

  wait_ready "kustomization/flux-system" "flux-system" "2m"
}

verify_infra_addons() {
  info "Forcing reconciliation of infra-addons source and kustomization..."
  flux reconcile source oci infra-addons || true
  flux reconcile kustomization infra-addons || true

  info "Waiting for infra-addons Kustomization to become ready..."
  wait_ready "kustomization/infra-addons" "flux-system" "5m"

  info "Waiting for cert-manager HelmReleases to become ready..."
  wait_ready "helmrelease/cert-manager" "flux-system" "3m"
  wait_ready "helmrelease/trust-manager" "flux-system" "3m"

  info "Waiting for external-secrets HelmRelease to become ready..."
  wait_ready "helmrelease/external-secrets" "flux-system" "5m"

  info "Verifying External Secrets Operator end-to-end secret synchronization..."
  cat <<'EOF' | kubectl apply -f -
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: test-fake-store
  namespace: default
spec:
  provider:
    fake:
      data:
      - key: /test/credential
        value: "flux-e2e-secret-token"
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: test-eso-sync
  namespace: default
spec:
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: test-fake-store
  target:
    name: test-eso-sync-secret
    creationPolicy: Owner
  data:
  - secretKey: token
    remoteRef:
      key: /test/credential
EOF

  wait_ready "externalsecret/test-eso-sync" "default" "2m"

  local secret_val
  secret_val=$(kubectl get secret test-eso-sync-secret -n default -o jsonpath='{.data.token}' | base64 -d)
  if [[ "${secret_val}" != "flux-e2e-secret-token" ]]; then
    error "ExternalSecret value mismatch: got '${secret_val}', expected 'flux-e2e-secret-token'"
    exit 1
  fi
  success "External Secrets Operator successfully synchronized secret from store."

  kubectl delete externalsecret test-eso-sync -n default --ignore-not-found=true
  kubectl delete secretstore test-fake-store -n default --ignore-not-found=true
  kubectl delete secret test-eso-sync-secret -n default --ignore-not-found=true

  info "Waiting for external-dns HelmRelease to become ready..."
  wait_ready "helmrelease/external-dns" "flux-system" "5m"

  info "Verifying ExternalDNS service discovery and record registration..."
  local test_host="test-app-${RANDOM}.test.local"
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: test-externaldns-service
  namespace: default
  annotations:
    external-dns.kubernetes.io/hostname: "${test_host}"
    external-dns.kubernetes.io/target: "192.168.1.100"
spec:
  ports:
  - port: 80
    name: http
EOF

  local found_record=0
  for _ in {1..16}; do
    if kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns --tail=50 2>&1 | grep -q "${test_host}"; then
      found_record=1
      break
    fi
    sleep 5
  done

  kubectl delete service test-externaldns-service -n default --ignore-not-found=true

  if [[ ${found_record} -ne 1 ]]; then
    error "ExternalDNS did not log record creation for ${test_host} within 80s!"
    kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns --tail=100 || true
    exit 1
  fi
  success "ExternalDNS detected service and registered record for ${test_host}."
}

verify_openziti_stack() {
  info "Waiting for ziti-controller HelmRelease to become ready..."
  wait_ready "helmrelease/ziti-controller" "flux-system" "5m"

  info "Waiting for ziti-router-enroll job to complete..."
  kubectl wait --for=condition=complete job/ziti-router-enroll -n openziti --timeout=5m || {
    error "ziti-router-enroll job failed!"
    echo "=== ENROLL JOB LOGS ==="
    kubectl logs -n openziti -l job-name=ziti-router-enroll --all-containers=true --tail=-1 || true
    echo "=== ENROLL JOB DESCRIBE ==="
    kubectl describe job ziti-router-enroll -n openziti || true
    exit 1
  }
  success "ziti-router-enroll job completed successfully."

  info "Waiting for ziti-router HelmRelease to become ready..."
  wait_ready "helmrelease/ziti-router" "flux-system" "3m"

  info "Verifying openziti pods are healthy and running..."
  kubectl get pods -n openziti
}


verify_keycloak_stack() {
  info "Waiting for keycloak deployment to become ready..."
  kubectl wait --for=condition=ready pod -l app=keycloak -n keycloak --timeout=5m

  info "Waiting for ziti-ext-jwt-config job to complete..."
  kubectl wait --for=condition=complete job/ziti-ext-jwt-config -n openziti --timeout=10m || {
    error "ziti-ext-jwt-config job failed!"
    echo "=== EXT JWT JOB LOGS ==="
    kubectl logs -n openziti -l job-name=ziti-ext-jwt-config --all-containers=true --tail=-1 || true
    echo "=== EXT JWT JOB DESCRIBE ==="
    kubectl describe job ziti-ext-jwt-config -n openziti || true
    exit 1
  }
  success "ziti-ext-jwt-config job completed successfully."
}

# --- Main Routine ---

main() {
  require_dependencies
  install_flux_operator
  publish_oci_artifacts
  validate_kustomize
  bootstrap_flux
  verify_infra_addons
  verify_openziti_stack
  verify_keycloak_stack

  echo -e "\n${GREEN}${BOLD}  ✔  Flux D2 bootstrap test completed successfully!${RESET}\n"
}

main "$@"