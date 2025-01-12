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
  for_each = var.deployement_approver
  username = each.key
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
