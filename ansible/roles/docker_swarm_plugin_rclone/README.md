# Docker Swarm Rclone Plugin Ansible Role

## Description

Installs and configures the Rclone Docker volume plugin (`rclone/docker-volume-rclone`) on Docker Swarm worker nodes. This allows Docker services to use rclone remotes as persistent storage volumes. The role specifically configures an rclone remote for DigitalOcean Spaces.

## Requirements

-   Docker installed and running on the target worker nodes.
-   Target nodes must be part of a Docker Swarm.
-   Environment variables `RCLONE_DIGITALOCEAN_ACCESS_KEY_ID` and `RCLONE_DIGITALOCEAN_SECRET_ACCESS_KEY` must be set on the Ansible control node.
-   Ansible version: 2.9

## Role Variables

Available variables are listed in `defaults/main.yaml`:

```yaml
# defaults/main.yaml
# docker_swarm_plugin_rclone_assets_path: "{{ role_path }}/assets"
# docker_swarm_plugin_rclone_digitalocean_access_key_id: "{{ lookup('env', 'RCLONE_DIGITALOCEAN_ACCESS_KEY_ID') }}"
# docker_swarm_plugin_rclone_digitalocean_secret_access_key: "{{ lookup('env', 'RCLONE_DIGITALOCEAN_SECRET_ACCESS_KEY') }}"
# docker_swarm_plugin_rclone_digitalocean_s3_enspoint: "nyc3.digitaloceanspaces.com"
```
These variables are used to template the `rclone.conf` file which is then pushed as a Docker Swarm config and used by the plugin.

## Dependencies

This role has no external Galaxy dependencies. It is assumed Docker is already installed on the target nodes.

## Example Playbook

```yaml
- hosts: swarm_workers
  become: yes
  roles:
    - role: xnok.infra_bootstrap_tools.docker_swarm_plugin_rclone
      # Ensure RCLONE_DIGITALOCEAN_ACCESS_KEY_ID and RCLONE_DIGITALOCEAN_SECRET_ACCESS_KEY
      # are set in the environment where Ansible is run.
```

## License

MIT

## Author Information

Created by xNok.
