---
"ansible-collection-infra-bootstrap-tools": minor
"ansible-role-k3s-flux-bootstrap": minor
"ansible-role-k3s-server": patch
"kubernetes-infra-addons": minor
---

Improve K3s / Flux Bootstrap support: add Flux CLI installation task, update OCI sync URL to the new fleet path format (`oci://…/kubernetes/fleet/<cluster>`), change `k3s_flux_bootstrap_cluster_name` default to `k3s`, and update `k3s_server_kubeconfig_mode` default to `644`. Add initial Kubernetes infra-addons fleet configuration with cert-manager, trust-manager, OpenZiti controller and router.
