#!/usr/bin/env bash
set -e

# Creates a kind cluster and bootstraps flux using D2 Gitless setup
kind create cluster --name flux-d2

# Install Flux CD
flux install

# Push our kubernetes directory as OCI artifact to registry
flux push artifact oci://ghcr.io/my-org/d2-fleet:latest \
  --path="./kubernetes/fleet" \
  --source="\$(git config --get remote.origin.url)" \
  --revision="\$(git rev-parse HEAD)"

# Apply OCIRepository to pull fleet from registry
cat <<EOF | kubectl apply -f -
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: fleet
  namespace: flux-system
spec:
  interval: 1m
  url: oci://ghcr.io/my-org/d2-fleet
  ref:
    tag: latest
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: fleet
  namespace: flux-system
spec:
  interval: 1m
  sourceRef:
    kind: OCIRepository
    name: fleet
  path: "./"
  prune: true
EOF

kubectl wait --for=condition=ready oci/fleet -n flux-system --timeout=1m
kubectl wait --for=condition=ready ks/fleet -n flux-system --timeout=2m
