# Ansible Collection: xnok.infra_bootstrap_tools

A collection of Ansible roles for bootstrapping and managing self-hosted projects and homelabs. Includes roles for Docker, Docker Swarm, Terraform, and various utilities.

**Repository:** [https://github.com/xNok/infra-bootstrap-tools](https://github.com/xNok/infra-bootstrap-tools)
**Homepage:** [https://github.com/xNok/infra-bootstrap-tools](https://xnok.github.io/infra-bootstrap-tools/)



## Roles

This collection includes the following roles:

-   **`docker`**: Installs and configures Docker on the target system.
-   **`docker_swarm_app_caddy`**: Deploys Caddy as a Docker Swarm service, providing automated HTTPS and reverse proxy capabilities.
-   **`docker_swarm_app_portainer`**: Deploys Portainer (both Agent and Server components) as a Docker Swarm service for managing your Swarm cluster.
-   **`docker_swarm_controller`**: Initializes a new Docker Swarm cluster on the target node, making it the first manager.
-   **`docker_swarm_manager`**: Configures a node to join an existing Docker Swarm cluster as a manager.
-   **`docker_swarm_node`**: Configures a node to join an existing Docker Swarm cluster as a worker node.
-   **`docker_swarm_plugin_rclone`**: Installs and configures the Rclone Docker volume plugin on Docker Swarm worker nodes, enabling versatile storage options.
-   **`terraform_aws`**: Manages AWS infrastructure resources using Terraform.
-   **`terraform_digitalocean`**: Manages DigitalOcean infrastructure resources using Terraform.
-   **`utils_affected_roles`**: A utility role designed to determine which Ansible roles are affected by changes in a Continuous Integration (CI) environment.
-   **`utils_rotate_docker_configs`**: A utility role for rotating Docker Swarm configurations.
-   **`utils_rotate_docker_secrets`**: A utility role for rotating Docker Swarm secrets.
-   **`utils_ssh_add`**: A utility role to dynamically set up an SSH agent on the Ansible control node (localhost) and add a private SSH key to it, facilitating secure connections to remote hosts.

## Usage

To use a role from this collection in your Ansible playbook, you can refer to it by its fully qualified name, for example:

```yaml
- hosts: your_target_nodes
  collections:
    - xnok.infra_bootstrap_tools
  roles:
    - role: docker
    # - role: xnok.infra_bootstrap_tools.docker # More explicit
```

Detailed usage instructions and example playbooks for each role can be found within their respective `README.md` files (once created).

## Dependencies

Specific dependencies for each role (e.g., required Python packages on the control node or target systems) will be listed in the `README.md` of the individual roles. Ensure that your environment meets these prerequisites before running the playbooks.

Common dependencies might include:
- Ansible (version compatible with the roles)
- Python
- Any SDKs or CLIs required by specific roles (e.g., `boto3` for AWS roles, `hvac` for Vault interactions if applicable).

## License

This collection is licensed under the MIT License.

-   MIT

See the `LICENSE` file in the main repository for more details.
