terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    sshclient = {
      source = "luma-planet/sshclient"
      version = "1.0.1"
    }
  }
}
