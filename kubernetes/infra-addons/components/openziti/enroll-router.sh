#!/bin/sh
set -e

APISERVER=https://kubernetes.default.svc
SA_TOKEN=$$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CA_CERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
K8S_NAMESPACE=$$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

# Idempotency: skip if secret already exists
HTTP_STATUS=$$(curl -sk -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $${SA_TOKEN}" \
  --cacert "$${CA_CERT}" \
  "$${APISERVER}/api/v1/namespaces/$${K8S_NAMESPACE}/secrets/ziti-router-enrollment")
if [ "$${HTTP_STATUS}" = "200" ]; then
  echo "Secret ziti-router-enrollment already exists, skipping."
  exit 0
fi

# Login to controller
ziti edge login \
  "https://$${ZITI_CTRL_EDGE_ADVERTISED_HOST}:$${ZITI_CTRL_EDGE_ADVERTISED_PORT}" \
  --yes \
  --username "$${ZITI_ADMIN_USER}" \
  --password "$${ZITI_ADMIN_PASS}"

get_router_field() {
  FIELD="$${1}"
  ziti edge list edge-routers 'name="ziti-router"' -j 2>/dev/null | \
    python3 -c "
import sys, json
d = json.load(sys.stdin).get('data', [])
if d:
    print(d[0].get('$${FIELD}') or '')
else:
    print('')
" 2>/dev/null || echo ""
}

# Delete existing router if it has no JWT (already enrolled or stale)
ROUTER_ID=$$(get_router_field id)
if [ -n "$${ROUTER_ID}" ]; then
  JWT=$$(get_router_field enrollmentJwt)
  if [ -z "$${JWT}" ]; then
    echo "Router id=$${ROUTER_ID} exists but enrollment JWT is gone — deleting to recreate..."
    set +e
    ziti edge delete edge-router "$${ROUTER_ID}"
    set -e
    RETRIES=15
    while [ "$${RETRIES}" -gt 0 ]; do
      STILL_ID=$$(get_router_field id)
      [ -z "$${STILL_ID}" ] && break
      echo "Waiting for deletion to propagate (retries left: $${RETRIES})..."
      sleep 3
      RETRIES=$$((RETRIES - 1))
    done
    ROUTER_ID=""
  fi
fi

if [ -z "$${ROUTER_ID}" ]; then
  ziti edge create edge-router ziti-router --tunneler-enabled
fi

JWT=$$(get_router_field enrollmentJwt)

if [ -z "$${JWT}" ]; then
  echo "ERROR: Could not retrieve enrollment JWT."
  exit 1
fi

JWT_B64=$$(echo -n "$${JWT}" | base64 -w 0)

# Create the Secret via Kubernetes API
curl -sk -X POST \
  -H "Authorization: Bearer $${SA_TOKEN}" \
  -H "Content-Type: application/json" \
  --cacert "$${CA_CERT}" \
  "$${APISERVER}/api/v1/namespaces/$${K8S_NAMESPACE}/secrets" \
  -d "{
    \"apiVersion\": \"v1\",
    \"kind\": \"Secret\",
    \"metadata\": {
      \"name\": \"ziti-router-enrollment\",
      \"namespace\": \"$${K8S_NAMESPACE}\"
    },
    \"type\": \"Opaque\",
    \"data\": {
      \"enrollmentJwt\": \"$${JWT_B64}\"
    }
  }"

echo "Secret ziti-router-enrollment created."
