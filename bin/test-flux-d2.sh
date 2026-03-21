#!/usr/bin/env bash
set -e

CLUSTER_NAME=${CLUSTER_NAME:-"flux-d2-test"}
SOURCE_URL=${SOURCE_URL:-"https://github.com/xNok/infra-bootstrap-tools"}
REVISION=${REVISION:-"local"}

# Check if kind cluster exists, if not assume we want to create it
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Creating Kind cluster: $CLUSTER_NAME"
  kind create cluster --name "$CLUSTER_NAME"
fi

echo "Starting local Docker registry if not already running..."
if ! docker ps | grep -q 'registry:2'; then
  docker run -d -p 5000:5000 --name registry registry:2
fi

echo "Connecting registry to kind network..."
docker network connect "kind" "registry" || true

echo "Installing Flux Operator via Helm..."
helm upgrade --install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system --create-namespace

echo "Waiting for Flux Operator to become ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=flux-operator -n flux-system --timeout=2m

echo "Pushing the local kubernetes/ folder as an OCI artifact to the local registry..."
flux push artifact oci://localhost:5000/flux-system:latest \
  --path="./kubernetes" \
  --source="${SOURCE_URL}" \
  --revision="${REVISION}"

echo "Bootstrapping cluster from OCI..."
kubectl apply -f kubernetes/fleet/k3s-openziti/flux-instance.yaml

echo "Waiting for FluxInstance to become ready..."
kubectl wait --for=condition=ready fluxinstance/flux -n flux-system --timeout=2m

echo "Waiting for generated OCIRepository to become ready..."
kubectl wait --for=condition=ready ocirepository/flux-system -n flux-system --timeout=1m

echo "Waiting for generated Kustomization to become ready..."
kubectl wait --for=condition=ready kustomization/flux-system -n flux-system --timeout=2m

echo "Flux D2 bootstrap test completed successfully!"
