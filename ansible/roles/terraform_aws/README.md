# Terraform AWS Ansible Role

## Description

Manages AWS infrastructure using Terraform. This role automates running `terraform apply` or `terraform destroy` for a Terraform configuration located within the role (in the `terraform/` directory). It supports backend configuration templating (e.g., for S3 backend) and can generate an Ansible inventory from Terraform outputs.

## Requirements

-   Terraform installed on the Ansible control node.
-   AWS credentials configured for Terraform (typically via environment variables or AWS CLI profiles).
-   The `diodonfrost.terraform` Ansible collection must be installed.
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# terraform_aws_backend_config: "{{ role_path }}/assets/backend.tf" # Path to a templated backend config (e.g. backend.tf.j2)
# terraform_aws_inventory_path: "{{ playbook_dir }}/inventory"
# terraform_aws_inventory_prefix: "aws-swarm"
# terraform_aws_inventory_user: "ubuntu"
# terraform_aws_destroy: false # Set to true to run 'terraform destroy'
```
The Terraform files themselves are located in the `terraform/` directory within the role and include their own variables defined in `terraform/variables.tf`. These can be passed via `terraform_vars` to the `diodonfrost.terraform` role.

The `assets/backend.tf.j2` template can be used to configure Terraform's S3 backend by setting appropriate variables.

## Dependencies

-   `diodonfrost.terraform` (Ansible Galaxy collection for running Terraform)

## Example Playbook

```yaml
- hosts: localhost
  connection: local
  gather_facts: no
  roles:
    - role: xnok.infra_bootstrap_tools.terraform_aws
      vars:
        # Variables for the diodonfrost.terraform role
        terraform_project_path: "{{ role_path }}/terraform" # Path to this role's terraform files
        terraform_state: "present" # or "absent" for destroy
        terraform_backend_config_path: "{{ role_path }}/rendered_backend.tf" # If using templated backend
        # terraform_vars: # Pass variables to your terraform configuration
        #   aws_region: "us-east-1"
        #   instance_type: "t3.micro"

        # Variables for this terraform_aws role
        terraform_aws_destroy: false
        # Variables for backend.tf.j2 if used, e.g.:
        # tf_s3_backend_bucket: "my-terraform-state-bucket"
        # tf_s3_backend_key: "aws/infra/terraform.tfstate"
        # tf_s3_backend_region: "us-east-1"
```

To destroy the infrastructure, set `terraform_aws_destroy: true` or `terraform_state: "absent"`.

## License

MIT

## Author Information

Created by xNok.
