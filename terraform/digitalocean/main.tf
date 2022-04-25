
/**
 * # DigitalOcean Project
 *
 * Projects let you organize your DigitalOcean resources 
 * (like Droplets, Spaces, and load balancers) into groups.
 */
resource "digitalocean_project" "infra-bootstrap-tools" {
  name        = "infra-bootstrap-tools"
  description = "Startup infra for small self-hosted project"
  purpose     = "IoT"
  environment = "Development"
  resources = digitalocean_droplet.node.*.urn
}

# Generate a new SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

# Reguster the new SSH key to digitalocean
resource "digitalocean_ssh_key" "infra" {
  name       = "infra-bootstrap-tools-digitalocean"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "digitalocean_droplet" "node" {
  count = var.worker_count

  image  = "ubuntu-20-04-x64"
  name   = "node${count.index}"
  region = "lon1"
  size   = "s-1vcpu-1gb"

  ssh_keys = [digitalocean_ssh_key.infra.id]
}

output "nodes_ip" {
  value = digitalocean_droplet.node.*.ipv4_address
}