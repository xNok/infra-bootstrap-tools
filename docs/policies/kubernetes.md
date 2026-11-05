# kubernetes.addons - Allowed Infra-Addon Resources

Enforces that kubernetes/infra-addons contains only addon controllers and infrastructure definitions (Namespace, HelmRepository, HelmRelease, ConfigMap, RBAC). Workload configurations (e.g. ExternalSecret, Ingress, Secrets) must not be defined in infra-addons and belong in fleet configurations. Non-standard resources must have an approved exception declared in policy-exceptions.yaml.

