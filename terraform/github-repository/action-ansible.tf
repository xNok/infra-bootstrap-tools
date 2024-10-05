/**
 * Github environnement secrets for Ansible
 *
 */
resource "github_actions_environment_secret" "ansible_inventory" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.digitalocean_environment.environment
  secret_name      = "ansible_inventory"
  plaintext_value  = templatefile(
    "${path.module}/templates/ansible_inventory.tpl",
    { 
      user = "root"
      prefix = "swarm"
      nodes = local.nodes_ips,
      managers = local.managers_ips,
    }
  )
}

resource "github_actions_environment_secret" "ansible_ssh" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.digitalocean_environment.environment
  secret_name      = "ansible_ssh_key"
  plaintext_value  = local.ssh_key
}

resource "github_actions_environment_secret" "ansible_known_hosts" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.digitalocean_environment.environment
  secret_name      = "ansible_known_hosts"
  plaintext_value  = templatefile(
    "${path.module}/templates/known_hosts.tpl",
    { 
      known_hosts = local.known_hosts
    }
  )
}
