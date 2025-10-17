output "managers_ips" {
  description = "Public IP addresses of the manager instances"
  value       = digitalocean_droplet.managers.*.ipv4_address
}

output "nodes_ips" {
  description = "Public IP addresses of the node instances"
  value       = digitalocean_droplet.nodes.*.ipv4_address
}

output "known_hosts" {
  description = "Known hosts entries for all instances"
  value       = local.known_hosts
}
