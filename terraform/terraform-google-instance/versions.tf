terraform {
  required_version = "~> 1.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 4.0"
    }

    sshclient = {
      source = "luma-planet/sshclient"
      version = "1.0.1"
    }
  }
}
