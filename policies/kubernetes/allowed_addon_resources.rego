# METADATA
# title: Allowed Infra-Addon Resources
# description: Enforces that kubernetes/infra-addons contains only addon controllers and infrastructure definitions (Namespace, HelmRepository, HelmRelease, ConfigMap, RBAC). Workload configurations (e.g. ExternalSecret, Ingress, Secrets) must not be defined in infra-addons and belong in fleet configurations. Non-standard resources must have an approved exception declared in policy-exceptions.yaml.
package kubernetes.addons

import rego.v1
import data.exceptions

default_allowed_kinds := {
	"Namespace",
	"HelmRepository",
	"HelmRelease",
	"ConfigMap",
	"ServiceAccount",
	"Role",
	"RoleBinding",
	"ClusterRole",
	"ClusterRoleBinding",
	"CustomResourceDefinition",
}

is_allowed if {
	default_allowed_kinds[input.kind]
}

is_allowed if {
	some ex in exceptions
	ex.kind == input.kind
	ex.namespace == input.metadata.namespace
}

is_allowed if {
	some ex in exceptions
	ex.kind == input.kind
	not object.get(ex, "namespace", null)
}

deny contains msg if {
	not is_allowed
	ns := object.get(input.metadata, "namespace", "cluster-scoped")
	name := object.get(input.metadata, "name", "unknown")
	msg := sprintf("Resource '%v/%v' of kind '%v' is not allowed in infra-addons. Infra-addons must only define addon controllers and their base prerequisites (Namespace, HelmRepository, HelmRelease, ConfigMap, RBAC). Workload and instance configurations (e.g. ExternalSecret, Ingress, ClusterSecretStore) belong in fleet clusters. If this is an approved exception, declare it in kubernetes/infra-addons/policy-exceptions.yaml", [ns, name, input.kind])
}
