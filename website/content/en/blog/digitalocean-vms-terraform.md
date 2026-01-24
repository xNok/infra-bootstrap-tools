---
title: "How to Provision VMs on DigitalOcean with Terraform"
date: 2024-01-28
author: xNok
summary: Step-by-step guide to provisioning virtual machines on DigitalOcean using Terraform for automated infrastructure deployment.
canonical_url: https://faun.pub/how-to-provision-vms-on-digitalocean-with-terraform-898515a0dbbc
tags:
  - Terraform
  - DigitalOcean
  - Cloud
  - Infrastructure as Code
---

# How to Provision VMs on DigitalOcean with Terraform

DigitalOcean provides affordable, reliable cloud infrastructure. Combined with Terraform, you can provision and manage Droplets (VMs) as code, making your infrastructure reproducible and maintainable.

## Why DigitalOcean and Terraform?

**Cost-Effective**: DigitalOcean offers competitive pricing perfect for small projects and homelabs.

**Simple API**: Clean, well-documented API that Terraform handles beautifully.

**Fast Provisioning**: Droplets spin up quickly for rapid iteration.

**Global Presence**: Deploy in multiple regions worldwide.

## Prerequisites

- DigitalOcean account with API token
- Terraform installed locally
- SSH key pair for server access

## Basic Terraform Configuration

```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "web" {
  image  = "ubuntu-22-04-x64"
  name   = "web-server"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
}
```

## Key Features

- **Multiple Droplets**: Create entire clusters with count or for_each
- **SSH Key Management**: Upload and assign SSH keys automatically
- **Firewall Rules**: Define security groups as code
- **Load Balancers**: Provision and configure load balancers
- **Block Storage**: Attach volumes for persistent data

## Best Practices

1. **Use Variables**: Keep tokens and sensitive data in variables
2. **Remote State**: Store state in DigitalOcean Spaces or Terraform Cloud
3. **Modules**: Create reusable modules for common patterns
4. **Tags**: Organize resources with tags for better management

## Integration with Ansible

After provisioning with Terraform, use Ansible for configuration management. Terraform can generate Ansible inventory automatically, creating a smooth workflow from infrastructure to application deployment.

Read the full article on Medium: [How to provision VM on Digital Ocean with Terraform](https://faun.pub/how-to-provision-vms-on-digitalocean-with-terraform-898515a0dbbc)
