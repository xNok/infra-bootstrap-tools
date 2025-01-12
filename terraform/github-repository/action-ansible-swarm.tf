/**
 * Github environnement and secrets for Ansible
 *
 */

resource "github_repository_environment" "docker_swarm" {
  repository       = data.github_repository.repo.name
  environment      = "docker_swarm"
  reviewers {
    users = data.github_user.deployement_approver.*.id
    # teams = [] an entire team can be approver
  }
}

resource "github_actions_environment_secret" "docker_swarm_ansible_inventory" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.docker_swarm.environment
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

resource "github_actions_environment_secret" "docker_swarm_ansible_ssh" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.docker_swarm.environment
  secret_name      = "ansible_ssh_key"
  plaintext_value  = local.ssh_key
}

resource "github_actions_environment_secret" "docker_swarm_ansible_known_hosts" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.docker_swarm.environment
  secret_name      = "ansible_known_hosts"
  plaintext_value  = templatefile(
    "${path.module}/templates/known_hosts.tpl",
    { 
      known_hosts = local.known_hosts
    }
  )
}
