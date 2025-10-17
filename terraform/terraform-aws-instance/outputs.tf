output "managers_ips" {
  description = "Public IP addresses of the manager instances"
  value       = aws_instance.managers.*.public_ip
}

output "nodes_ips" {
  description = "Public IP addresses of the node instances"
  value       = aws_instance.nodes.*.public_ip
}

output "known_hosts" {
  description = "Known hosts entries for all instances"
  value       = local.known_hosts
}
