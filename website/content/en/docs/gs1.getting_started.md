---
title: "🚀 Getting Started"
slug: getting-started-deploy-your-infrastructure
---

This guide walks you through deploying a single-node (expandable) infrastructure on DigitalOcean using the `infra-bootstrap-tools`.

We'll use the `make up` target for deployment and `make down` for destruction.

#### Prerequisites

Before you begin, ensure you have the following tools and accounts:

*   **Ansible:** [Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
*   **Terraform:** [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
*   **DigitalOcean Account:** You'll need an account to provision resources.
*   **Secret Management Tool:** You'll need a way to provide sensitive data to Ansible.
    *   **Recommended (That's what I use):** 1Password & 1Password CLI (`op`). [Set up 1Password CLI](https://developer.1password.com/docs/cli/get-started/). The examples in this guide use 1Password.
    *   **Alternatives:** Ansible Vault, environment variables, direct input in variable files (not recommended for sensitive data in Git), or other Ansible lookup plugins.

##### Development Environment Setup

While not strictly required for deploying the infrastructure, if you plan to contribute to this project or customize it extensively, setting up a consistent development environment is recommended.

*   **Using the Setup Script**: This project includes a helper script to install common tools used for development, such as `pre-commit` for linting, `ansible`, `hugo` for the documentation site, etc. You can find this script at [`./bin/bash/setup.sh`](https://github.com/xNok/infra-bootstrap-tools/blob/main/bin/bash/setup.sh). To install specific tools, run:
    ```bash
    ./bin/bash/setup.sh <tool_name_1> <tool_name_2>
    ```
    For example, to install `pre-commit` and `hugo`:
    ```bash
    ./bin/bash/setup.sh pre-commit hugo
    ```
    Run the script without arguments or with an invalid tool name to see the list of available tools.

*   **Using Gitpod**: For a cloud-based, pre-configured development environment, you can use Gitpod. This is the quickest way to get started without installing anything on your local machine. Look for the "Open in Gitpod" button in the main [`README.md`](https://github.com/xNok/infra-bootstrap-tools/blob/main/README.md) of the project.

#### Configuration - Secrets Management

Sensitive information, such as API keys and tokens, is required to provision and configure the infrastructure. This project requires sensitive information like API keys. The author prefers using 1Password for managing these, and the examples show this method. However, you can adapt this to your preferred secret management tool (e.g., Ansible Vault, environment variables, or other lookup plugins).

If using 1Password, ensure your CLI is configured and you have access to the specified vault. If using other methods, ensure your secrets are available to Ansible in the way your chosen tool requires.

The key Ansible variable files involved are:

*   [`ansible/playbooks/host_vars/localhost.yml`](https://github.com/xNok/infra-bootstrap-tools/blob/main/ansible/playbooks/host_vars/localhost.yml): Defines where to find secrets for DigitalOcean token, SSH key details, and AWS credentials (for Terraform backend).
    *   You will need to store items like `tf_digitalocean_access_token`, `ssh_key_name`, `do_ssh_key_public_path`, `do_ssh_key_private_path`, `aws_access_key_id`, `aws_secret_access_key`.
*   [`ansible/playbooks/group_vars/all.yml`](https://github.com/xNok/infra-bootstrap-tools/blob/main/ansible/playbooks/group_vars/all.yml): Defines where to find Rclone DigitalOcean secrets.
    *   Look for variables like `rclone_digitalocean_access_key_id` and `rclone_digitalocean_secret_access_key`.
*   [`ansible/playbooks/group_vars/managers.yaml`](https://github.com/xNok/infra-bootstrap-tools/blob/main/ansible/playbooks/group_vars/managers.yaml): Defines where to find Caddy secrets.
    *   Look for variables like `CADDY_GITHUB_APP_CLIENT_ID` and `CADDY_GITHUB_APP_CLIENT_SECRET`.

**Note:** Refer to the role documentation if you need a better indication of all the available configurations. I have yet to write/generate a reference for those.

#### Deployment Steps

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-username/infra-bootstrap-tools.git # Replace with the actual repository URL
    cd infra-bootstrap-tools
    ```

2.  **Configure Secrets:**
    Ensure your chosen secret management tool is set up with all necessary secrets as outlined in the "Configuration - Secrets Management" section above. If not using 1Password, you will need to modify the variable files to reflect your chosen secret retrieval method.

3.  **Deploy Infrastructure:**
    The `make up` command provisions the infrastructure on DigitalOcean, sets up Docker, initializes Docker Swarm, and deploys Caddy and Portainer.
    ```bash
    make up
    ```

4.  **Accessing Services:**
   * Your caddy security portal should be accessible at `https://auth.[YOUR_DOMAIN]/portal`, from there you should have a link to access Portainer, which is waiting for you to set up your admin account. (**Note**: you need to be quick, otherwise Portainer will lock itself, and you will need to restart the Portainer container)
    

#### Managing the Infrastructure

*   **Scaling:**
    This setup is designed to be scalable. You can adjust the number of manager and worker nodes by modifying variables in your Terraform configuration (e.g., in [`terraform/variables.tf`](https://github.com/xNok/infra-bootstrap-tools/blob/main/ansible/roles/terraform_digitalocean/terraform/variables.tf)). The playbooks can also be adapted to integrate OVH dedicated servers or other providers, though this may require further customization.

*   **Destroying Infrastructure:**
    To decommission all resources created by Terraform on DigitalOcean, use the `make down` command.
    ```bash
    make down
    ```
    This will remove the Droplets and any other associated resources.

#### Next Steps/Further Reading

*   **[Understanding Ansible Concepts]({{< relref "./b1.ansible_concepts.md" >}})**: Learn about core Ansible concepts.
*   **[Caddy Web Server]({{< relref "./a1.caddy.md" >}})**: Deep dive into Caddy's role.
*   **[Portainer Management UI]({{< relref "./a2.portainer.md" >}})**: Learn about Portainer.
*   Review other articles in the "Tools Introduction" and "Learn the Tools" sections of the main [`README.md`](https://github.com/xNok/infra-bootstrap-tools/blob/main/README.md) for a deeper understanding of the components used.
