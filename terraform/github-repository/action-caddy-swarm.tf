/**
 * # Caddy configuration
 *
 * We need to collect some configuration so we can configure Caddy
 * This include auth, and DNS configurations
 */


 /**
 * Github environnement secrets placeholder for caddy
 *
 */
resource "github_actions_environment_secret" "caddy_github_client_id" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.docker_swarm.environment
  secret_name      = "CADDY_GITHUB_CLIENT_ID"
  lifecycle {
    # This resource is intended as placeholder chnaging the value after creation is ok
    ignore_changes = [
      plaintext_value,
    ]
  }
}

resource "github_actions_environment_secret" "caddy_github_client_secret" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.docker_swarm.environment
  secret_name      = "CADDY_GITHUB_CLIENT_SECRET"
  lifecycle {
    # This resource is intended as placeholder chnaging the value after creation is ok
    ignore_changes = [
      plaintext_value,
    ]
  }
}

# Generate a new SSH key
resource "tls_private_key" "caddy_jwt_shared_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "github_actions_environment_secret" "caddy_jwt_shared_key" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.docker_swarm.environment
  secret_name      = "CADDY_JWT_SHARED_KEY"
  plaintext_value  = tls_private_key.caddy_jwt_shared_key.private_key_openssh

  lifecycle {
    # This resource is intended as placeholder chnaging the value after creation is ok
    ignore_changes = [
      plaintext_value,
    ]
  }
}

resource "github_actions_environment_secret" "caddy_digitalocean_api_token" {
  repository       = data.github_repository.repo.name
  environment      = github_repository_environment.docker_swarm.environment
  secret_name      = "CADDY_DIGITALOCEAN_API_TOKEN"
  plaintext_value  = ""

  lifecycle {
    # This resource is intended as placeholder chnaging the value after creation is ok
    ignore_changes = [
      plaintext_value,
    ]
  }
}