#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/../../.." && pwd)

CLUSTER_NAME=${CLUSTER_NAME:-"flux-d2-test"}
SOURCE_URL=${SOURCE_URL:-"https://github.com/xNok/infra-bootstrap-tools"}
REVISION=${REVISION:-"local"}
FLEET_NAME=${FLEET_NAME:-"openziti"}
REGISTRY_NAME=${REGISTRY_NAME:-"kind-registry"}
REGISTRY_PORT=${REGISTRY_PORT:-"5000"}

require_resource() {
  local resource="$1"
  local namespace="$2"
  echo "Checking resource exists: ${resource} (ns=${namespace})"
  kubectl get "${resource}" -n "${namespace}" > /dev/null
}

wait_ready() {
  local resource="$1"
  local namespace="$2"
  local timeout="$3"
  echo "Waiting for readiness: ${resource} (ns=${namespace}, timeout=${timeout})"
  kubectl wait --for=condition=ready "${resource}" -n "${namespace}" --timeout="${timeout}"
}

echo "Setting up local Kind cluster and registry..."
CLUSTER_NAME="${CLUSTER_NAME}" REGISTRY_NAME="${REGISTRY_NAME}" REGISTRY_PORT="${REGISTRY_PORT}" \
  "${ROOT_DIR}/bin/setup-kind-local-registry.sh"

echo "Installing Flux Operator via Helm..."
helm upgrade --install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system --create-namespace

echo "Waiting for Flux Operator to become ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=flux-operator -n flux-system --timeout=2m

echo "Pushing the local kubernetes/ folder as an OCI artifact to the local registry..."
flux push artifact "oci://localhost:${REGISTRY_PORT}/flux-system:latest" \
  --path="${ROOT_DIR}/kubernetes" \
  --source="${SOURCE_URL}" \
  --revision="${REVISION}"

echo "Validating local Kustomize entrypoints..."
kubectl kustomize "${ROOT_DIR}/kubernetes/fleet/${FLEET_NAME}" > /dev/null
kubectl kustomize "${ROOT_DIR}/kubernetes/infra" > /dev/null

echo "Bootstrapping cluster from OCI..."
kubectl apply -f "${ROOT_DIR}/kubernetes/fleet/${FLEET_NAME}/flux-system/flux-instance.yaml"

echo "Waiting for FluxInstance to become ready..."
wait_ready "fluxinstance/flux" "flux-system" "2m"

echo "Waiting for generated OCIRepository to become ready..."
wait_ready "ocirepository/flux-system" "flux-system" "1m"

echo "Waiting for generated Kustomization to become ready..."
wait_ready "kustomization/flux-system" "flux-system" "2m"

echo "Validating D2 fleet resources..."
require_resource "resourceset/infra-components" "flux-system"
wait_ready "resourceset/infra-components" "flux-system" "2m"

echo "Waiting for infra Kustomizations to become ready..."
wait_ready "kustomization/infra-sources" "flux-system" "2m"
wait_ready "kustomization/infra-cert-manager" "flux-system" "3m"
wait_ready "kustomization/infra-openziti" "flux-system" "3m"
wait_ready "kustomization/infra-update-policies" "flux-system" "2m"

echo "Validating image automation policy resources..."
require_resource "imagerepository/openziti-controller" "flux-system"
require_resource "imagepolicy/openziti-controller" "flux-system"
require_resource "imagerepository/openziti-router" "flux-system"
require_resource "imagepolicy/openziti-router" "flux-system"

echo "Waiting for image repositories to become ready..."
wait_ready "imagerepository/openziti-controller" "flux-system" "3m"
wait_ready "imagerepository/openziti-router" "flux-system" "3m"

echo "Debug snapshot of image policies..."
kubectl get imagepolicy -n flux-system -o wide

echo "Flux D2 bootstrap test completed successfully!"