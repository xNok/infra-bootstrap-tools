/**
 * # Github Repository
 *
 * The Terraform configuration need to update Github Action Variable 
 * This way we can manage secret and inventory automatically
 */

data "github_repository" "repo" {
  full_name = var.repo_name
}

data "github_user" "deployement_approver" {
  username = var.deployement_approver
}

resource "github_repository_environment" "digitalocean_environment" {
  repository       = data.github_repository.repo.name
  environment      = "digitalocean"
  reviewers {
    users = [data.github_user.deployement_approver.id]
    # teams = [] an entire team can be approver
  }

  deployment_branch_policy {
    protected_branches     = true #the main branch protection definition is below
    custom_branch_policies = false
  }
}

/**
 * Github branch permissions
 *
 */
resource "github_branch_protection" "main" {
  repository_id     = data.github_repository.repo.node_id

  pattern          = "main"
  # enforce_admins   = true

  # Configure the check api
  required_status_checks {
    strict   = false
    contexts = ["validate"]
  }
}

/**
 * Github environnement secrets for Ansible
 *
 */
resource "github_actions_environment_secret" "inventory" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.digitalocean_environment.environment
  secret_name      = "inventory"
  plaintext_value  = templatefile(
    "${path.module}/templates/ansible_inventory.tpl",
    { 
      user = "root"
      prefix = "swarm"
      nodes = digitalocean_droplet.nodes.*.ipv4_address,
      managers = digitalocean_droplet.managers.*.ipv4_address
    }
  )
}

resource "github_actions_environment_secret" "ssh" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.digitalocean_environment.environment
  secret_name      = "ssh_key"
  plaintext_value  = tls_private_key.ssh.private_key_pem
}

data "sshclient_host" "nodes" {
  count = length(digitalocean_droplet.nodes)
  hostname = digitalocean_droplet.nodes[count.index].ipv4_address
  username = "keyscan"
  insecure_ignore_host_key = true # we use this to scan and obtain the key
}

data "sshclient_host" "managers" {
  count = length(digitalocean_droplet.managers)
  hostname = digitalocean_droplet.managers[count.index].ipv4_address
  username = "keyscan"
  insecure_ignore_host_key = true # we use this to scan and obtain the key
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [digitalocean_droplet.nodes, digitalocean_droplet.managers]

  create_duration = "30s"
}

data "sshclient_keyscan" "keyscan_nodes" {
  count  = length(data.sshclient_host.nodes)
  host_json = data.sshclient_host.nodes[count.index].json
  depends_on = [time_sleep.wait_30_seconds]
}

data "sshclient_keyscan" "keyscan_managers" {
  count  = length(data.sshclient_host.managers)
  host_json = data.sshclient_host.managers[count.index].json
  depends_on = [time_sleep.wait_30_seconds]
}

locals {
  known_hosts = merge(
    {for k, v in data.sshclient_host.nodes : v.hostname => data.sshclient_keyscan.keyscan_nodes[k].authorized_key },
    {for k, v in data.sshclient_host.managers : v.hostname => data.sshclient_keyscan.keyscan_managers[k].authorized_key },
  )
}

resource "github_actions_environment_secret" "known_hosts" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.digitalocean_environment.environment
  secret_name      = "known_hosts"
  plaintext_value  = templatefile(
    "${path.module}/templates/known_hosts.tpl",
    { 
      known_hosts = local.known_hosts
    }
  )
}
