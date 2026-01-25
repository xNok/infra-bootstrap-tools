output "managers_ips" {
  value = module.swarm_cluster.managers_ips
}

output "nodes_ips" {
  value = module.swarm_cluster.nodes_ips
}

output "known_hosts" {
  value = module.swarm_cluster.known_hosts
}
