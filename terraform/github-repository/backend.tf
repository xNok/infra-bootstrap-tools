terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = var.organization_name

    workspaces {
      name = "infra-bootstrap-tools-github-repository"
    }
  }
}
