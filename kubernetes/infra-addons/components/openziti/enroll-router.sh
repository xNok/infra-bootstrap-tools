#!/bin/sh
set -e

APISERVER=https://kubernetes.default.svc
SA_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CA_CERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
K8S_NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

# Idempotency: skip if secret already exists
HTTP_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer ${SA_TOKEN}" \
  --cacert "${CA_CERT}" \
  "${APISERVER}/api/v1/namespaces/${K8S_NAMESPACE}/secrets/ziti-router-enrollment")
if [ "${HTTP_STATUS}" = "200" ]; then
  echo "Secret ziti-router-enrollment already exists, skipping."
  exit 0
fi

# Login to controller
ziti edge login \
  "https://${ZITI_CTRL_EDGE_ADVERTISED_HOST}:${ZITI_CTRL_EDGE_ADVERTISED_PORT}" \
  --yes \
  --username "${ZITI_ADMIN_USER}" \
  --password "${ZITI_ADMIN_PASS}"

# Create edge router (idempotent)
EXISTING=$(ziti edge list edge-routers 'name="ziti-router"' -j 2>/dev/null | grep '"id"' | wc -l)
if [ "${EXISTING}" -gt 0 ]; then
  echo "Edge router 'ziti-router' already exists."
else
  ziti edge create edge-router ziti-router --tunneler-enabled
fi

# Get enrollment JWT
JWT=$(ziti edge list edge-routers 'name="ziti-router"' -j | \
  python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d[0]['enrollmentJwt'])" 2>/dev/null || echo "")

if [ -z "${JWT}" ]; then
  echo "ERROR: Could not retrieve enrollment JWT. Router may already be enrolled."
  exit 1
fi

JWT_B64=$(echo -n "${JWT}" | base64 -w 0)

# Create the Secret via Kubernetes API
curl -sk -X POST \
  -H "Authorization: Bearer ${SA_TOKEN}" \
  -H "Content-Type: application/json" \
  --cacert "${CA_CERT}" \
  "${APISERVER}/api/v1/namespaces/${K8S_NAMESPACE}/secrets" \
  -d "{
    \"apiVersion\": \"v1\",
    \"kind\": \"Secret\",
    \"metadata\": {
      \"name\": \"ziti-router-enrollment\",
      \"namespace\": \"${K8S_NAMESPACE}\"
    },
    \"type\": \"Opaque\",
    \"data\": {
      \"enrollmentJwt\": \"${JWT_B64}\"
    }
  }"

echo "Secret ziti-router-enrollment created."
