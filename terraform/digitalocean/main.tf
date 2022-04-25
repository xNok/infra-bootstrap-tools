
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

data "digitalocean_ssh_key" "infra" {
  name = "infra-bootstrap-tools"
}

resource "digitalocean_droplet" "node" {
  count = var.worker_count

  image  = "ubuntu-20-04-x64"
  name   = "node${count.index}"
  region = "lon1"
  size   = "s-1vcpu-1gb"

  ssh_keys = [data.digitalocean_ssh_key.infra.id]
}

output "nodes_ip" {
  value = digitalocean_droplet.node.*.ipv4_address
}

# generate inventory file for Ansible
data "template_file" "inventory" {
    template = "${file("./templates/ansible_inventory.tpl")}"

    vars = {
      nodes = digitalocean_droplet.node.*.ipv4_address
      managers = digitalocean_droplet.node.*.ipv4_address
    }
}