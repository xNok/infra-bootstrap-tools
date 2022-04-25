/**
 * # Github Repository
 *
 * The Terraform configuration need to update Github Action Variable 
 * This way we can manage secret and inventory automatically
 */

data "github_repository" "repo" {
  full_name = var.repo_name
}

resource "github_repository_environment" "digitalocean_environment" {
  repository       = data.github_repository.repo.name
  environment      = "digitalocean"
}

resource "github_actions_environment_secret" "test_secret" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.digitalocean_environment.environment
  secret_name      = "test_secret_name"
  plaintext_value  = "%s"
}

resource "github_actions_environment_secret" "inventory" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.digitalocean_environment.environment
  secret_name      = "inventory"
  plaintext_value  = templatefile(
    "${path.module}/templates/ansible_inventory.tpl",
    { 
      nodes = digitalocean_droplet.node.*.ipv4_address,
      managers = digitalocean_droplet.node.*.ipv4_address
    }
  )
}

resource "github_actions_environment_secret" "ssh" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.digitalocean_environment.environment
  secret_name      = "ssh_key"
  plaintext_value  = tls_private_key.ssh.private_key_pem
}

