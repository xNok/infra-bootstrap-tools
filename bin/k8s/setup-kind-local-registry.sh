#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME=${CLUSTER_NAME:-"kind"}
REGISTRY_NAME=${REGISTRY_NAME:-"kind-registry"}
REGISTRY_PORT=${REGISTRY_PORT:-"5000"}
KIND_NODE_IMAGE=${KIND_NODE_IMAGE:-""}
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KIND_CONFIG_TEMPLATE=${KIND_CONFIG_TEMPLATE:-"${SCRIPT_DIR}/kind/config/cluster-with-registry.yaml.tpl"}
LOCAL_REGISTRY_TEMPLATE=${LOCAL_REGISTRY_TEMPLATE:-"${SCRIPT_DIR}/kind/config/local-registry-hosting.yaml.tpl"}

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

need_cmd kind
need_cmd docker
need_cmd kubectl

need_file() {
  local file_path="$1"
  if [[ ! -f "${file_path}" ]]; then
    echo "Missing required file: ${file_path}" >&2
    exit 1
  fi
}

render_template() {
  local template_file="$1"
  local output_file="$2"

  sed \
    -e "s|__REGISTRY_PORT__|${REGISTRY_PORT}|g" \
    -e "s|__REGISTRY_NAME__|${REGISTRY_NAME}|g" \
    "${template_file}" > "${output_file}"
}

need_file "${KIND_CONFIG_TEMPLATE}"
need_file "${LOCAL_REGISTRY_TEMPLATE}"

create_cluster() {
  if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Kind cluster already exists: ${CLUSTER_NAME}"
    return
  fi

  echo "Creating Kind cluster: ${CLUSTER_NAME}"
  local kind_config
  kind_config=$(mktemp)

  render_template "${KIND_CONFIG_TEMPLATE}" "${kind_config}"

  if [[ -n "${KIND_NODE_IMAGE}" ]]; then
    kind create cluster --name "${CLUSTER_NAME}" --config "${kind_config}" --image "${KIND_NODE_IMAGE}"
  else
    kind create cluster --name "${CLUSTER_NAME}" --config "${kind_config}"
  fi

  rm -f "${kind_config}"
}

create_registry() {
  if docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" >/dev/null 2>&1; then
    echo "Registry container already running: ${REGISTRY_NAME}"
    return
  fi

  echo "Starting local registry: ${REGISTRY_NAME}"
  docker run -d --restart=always -p "${REGISTRY_PORT}:5000" --name "${REGISTRY_NAME}" registry:2 >/dev/null
}

connect_registry_to_kind_network() {
  if docker network inspect kind >/dev/null 2>&1; then
    if [[ -z "$(docker network inspect kind -f '{{range .Containers}}{{println .Name}}{{end}}' | grep -x "${REGISTRY_NAME}" || true)" ]]; then
      echo "Connecting ${REGISTRY_NAME} to kind network"
      docker network connect kind "${REGISTRY_NAME}" >/dev/null
    else
      echo "Registry already connected to kind network"
    fi
  else
    echo "Kind network not found (cluster may not be running)" >&2
    exit 1
  fi
}

document_local_registry() {
  local registry_manifest
  registry_manifest=$(mktemp)
  render_template "${LOCAL_REGISTRY_TEMPLATE}" "${registry_manifest}"
  kubectl apply -f "${registry_manifest}"
  rm -f "${registry_manifest}"
}

create_cluster
create_registry
connect_registry_to_kind_network
document_local_registry

echo "Local Kind + registry setup complete"
echo "  Cluster:  ${CLUSTER_NAME}"
echo "  Registry: localhost:${REGISTRY_PORT} (container: ${REGISTRY_NAME})"
