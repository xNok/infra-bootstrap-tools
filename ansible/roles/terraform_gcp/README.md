# Terraform GCP Ansible Role

## Description

Manages Google Cloud Platform (GCP) infrastructure using Terraform. This role automates running `terraform apply` or `terraform destroy` for a Terraform configuration located within the role (in the `terraform/` directory). It supports backend configuration and can generate an Ansible inventory from Terraform outputs.

## Requirements

-   Terraform installed on the Ansible control node.
-   GCP credentials configured for Terraform (e.g., `GOOGLE_APPLICATION_CREDENTIALS` environment variable or `gcloud auth application-default login`).
-   The `diodonfrost.terraform` Ansible collection must be installed.
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# terraform_gcp_backend_config: "{{ role_path }}/assets/backend.tf" # Path to backend config
# terraform_gcp_inventory_path: "{{ playbook_dir }}/inventory"
# terraform_gcp_inventory_prefix: "gcp-swarm"
# terraform_gcp_inventory_user: "root" # or the username used in GCP instances (often tied to the user running terraform if using OS Login, or 'ubuntu' etc.)
# terraform_gcp_destroy: false # Set to true to run 'terraform destroy'
```

The Terraform files themselves are located in the `terraform/` directory within the role and include their own variables defined in `terraform/variables.tf`. These can be passed via `terraform_vars` to the `diodonfrost.terraform` role.

## Dependencies

-   `diodonfrost.terraform` (Ansible Galaxy collection for running Terraform)

## Example Playbook

```yaml
- hosts: localhost
  connection: local
  gather_facts: no
  roles:
    - role: xnok.infra_bootstrap_tools.terraform_gcp
      vars:
        # Variables for the diodonfrost.terraform role
        terraform_project_path: "{{ role_path }}/terraform"
        terraform_state: "present"

        # Variables for this terraform_gcp role
        terraform_gcp_destroy: false

        # Terraform variables
        # terraform_vars:
        #   gcp_project_id: "my-gcp-project-id"
        #   gcp_region: "europe-west1"
        #   gcp_zone: "europe-west1-b"
        #   manager_count: 1
        #   worker_count: 2
```

## License

MIT

## Author Information

Created by xNok.
