/**
 * 
 * We need to collect the list of machines accross the different cloud provider 
 * so we can configure variables in this repository for Ansible to take over and provision them
 */

data "terraform_remote_state" "digitalocean" {
  backend = "remote"

  config = {
    organization = var.tf_organization_name
    workspaces = {
      name = "infra-bootstrap-tools-digitalocean"
    }
  }
}

locals {
  nodes_ips = concat(
    data.terraform_remote_state.digitalocean.outputs.nodes_ips
  )

  managers_ips = concat(
    data.terraform_remote_state.digitalocean.outputs.managers_ips
  )

  known_hosts = concat(
    data.terraform_remote_state.digitalocean.outputs.known_hosts
  )

  ssh_key = concat(
    data.terraform_remote_state.digitalocean.outputs.ssh_key
  )
}