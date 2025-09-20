# Terraform DigitalOcean Ansible Role

## Description

Manages DigitalOcean infrastructure using Terraform. This role automates running `terraform apply` or `terraform destroy` for a Terraform configuration located within the role (in the `terraform/` directory). It supports backend configuration and can generate an Ansible inventory from Terraform outputs.

## Requirements

-   Terraform installed on the Ansible control node.
-   DigitalOcean API token configured for Terraform (typically via the `DIGITALOCEAN_TOKEN` environment variable).
-   The `diodonfrost.terraform` Ansible collection must be installed.
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# terraform_digitalocean_backend_config: "{{ role_path }}/assets/backend.tf" # Path to backend config
# terraform_digitalocean_inventory_path: "{{ playbook_dir }}/inventory"
# terraform_digitalocean_inventory_prefix: "do-swarm"
# terraform_digitalocean_inventory_user: "root"
# terraform_digitalocean_destroy: false # Set to true to run 'terraform destroy'
```
The Terraform files themselves are located in the `terraform/` directory within the role and include their own variables defined in `terraform/variables.tf`. These can be passed via `terraform_vars` to the `diodonfrost.terraform` role.
The `assets/backend.tf` can be used to configure Terraform's S3-compatible backend (e.g. DigitalOcean Spaces).

## Dependencies

-   `diodonfrost.terraform` (Ansible Galaxy collection for running Terraform)

## Example Playbook

```yaml
- hosts: localhost
  connection: local
  gather_facts: no
  roles:
    - role: xnok.infra_bootstrap_tools.terraform_digitalocean
      vars:
        # Variables for the diodonfrost.terraform role
        terraform_project_path: "{{ role_path }}/terraform" # Path to this role's terraform files
        terraform_state: "present" # or "absent" for destroy
        # terraform_backend_config_path: "{{ role_path }}/assets/backend.tf" # If using this backend config
        # terraform_vars: # Pass variables to your terraform configuration
        #   do_token: "{{ lookup('env', 'DIGITALOCEAN_TOKEN') }}"
        #   do_region: "nyc3"
        #   droplet_size: "s-1vcpu-1gb"

        # Variables for this terraform_digitalocean role
        terraform_digitalocean_destroy: false
        # Variables for backend.tf if used, e.g. for DO Spaces:
        # tf_s3_backend_endpoint: "nyc3.digitaloceanspaces.com"
        # tf_s3_backend_access_key: "{{ lookup('env', 'DO_SPACES_ACCESS_KEY') }}"
        # tf_s3_backend_secret_key: "{{ lookup('env', 'DO_SPACES_SECRET_KEY') }}"
        # tf_s3_backend_bucket: "my-terraform-state-bucket"
        # tf_s3_backend_key: "digitalocean/infra/terraform.tfstate"
```

To destroy the infrastructure, set `terraform_digitalocean_destroy: true` or `terraform_state: "absent"`.

## License

MIT

## Author Information

Created by xNok.
