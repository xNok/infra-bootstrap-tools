terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.25"
    }
    github = {
      source = "integrations/github"
      version = "~> 5.0"
    }

    tls = {
      source = "hashicorp/tls"
      version = "~> 3.3"
    }

    sshclient = {
      source = "luma-planet/sshclient"
      version = "1.0.1"
    }
  }
}

provider "sshclient" {
  # Configuration options
}

provider "digitalocean" {
  # Configuration options
}
provider "github" {
  # Configuration options
}

provider "tls" {
  # Configuration options
}
