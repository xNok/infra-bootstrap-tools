output "managers_ips" {
  value = digitalocean_droplet.managers.*.ipv4_address
}

output "nodes_ips" {
  value = digitalocean_droplet.nodes.*.ipv4_address
}

output "known_hosts" {
  value = local.known_hosts
}

output "ssh_key" {
  sensitive = true
  value = tls_private_key.ssh.private_key_pem
}