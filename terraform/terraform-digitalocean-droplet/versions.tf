terraform {
  required_version = "~> 1.11"

  required_providers {

    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~>2.25"
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
