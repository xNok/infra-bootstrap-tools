terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "nokwebspace"

    workspaces {
      name = "infra-bootstrap-tools-digitalocean"
    }
  }
}