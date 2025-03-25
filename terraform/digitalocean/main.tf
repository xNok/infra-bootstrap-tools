locals {
  project_name = "infra-bootstrap-tools"
}
/**
 * # DigitalOcean Project
 *
 * Projects let you organize your DigitalOcean resources 
 * (like Droplets, Spaces, and load balancers) into groups.
 */
resource "digitalocean_project" "infra-bootstrap-tools" {
  name        = local.project_name
  description = "Startup infra for small self-hosted project"
  purpose     = "IoT"
  environment = "Development"
  resources = concat(
    digitalocean_droplet.nodes.*.urn,
    digitalocean_droplet.managers.*.urn
  )
}

# Generate a new SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

# Reguster the new SSH key to digitalocean
resource "digitalocean_ssh_key" "infra" {
  name       = "${local.project_name}-digitalocean"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "digitalocean_droplet" "managers" {
  count = var.manager_count

  image  = "ubuntu-20-04-x64"
  name   = "manager${count.index}"
  region = "lon1"
  size   = var.manager_size

  monitoring = true

  ssh_keys = [digitalocean_ssh_key.infra.id]
}

resource "digitalocean_droplet" "nodes" {
  count = var.worker_count

  image  = "ubuntu-20-04-x64"
  name   = "node${count.index}"
  region = "lon1"
  size   = var.worker_size

  monitoring = true

  ssh_keys = [digitalocean_ssh_key.infra.id]
}
