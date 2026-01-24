output "managers_ips" {
  value = [for i in google_compute_instance.managers : i.network_interface[0].access_config[0].nat_ip]
}

output "nodes_ips" {
  value = [for i in google_compute_instance.nodes : i.network_interface[0].access_config[0].nat_ip]
}

output "known_hosts" {
  value = local.known_hosts
}
