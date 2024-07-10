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
