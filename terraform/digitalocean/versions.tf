terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.17.1"
    }
    github = {
      source = "integrations/github"
      version = "4.23.0"
    }
  }
}

provider "digitalocean" {
  # Configuration options
}
provider "github" {
  # Configuration options
}
