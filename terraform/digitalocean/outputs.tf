output "managers_ip" {
  value = digitalocean_droplet.managers.*.ipv4_address
}

output "nodes_ip" {
  value = digitalocean_droplet.nodes.*.ipv4_address
}
