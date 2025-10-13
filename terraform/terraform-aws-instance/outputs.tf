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
  value       = join("\n", keys(data.external.ssh_keyscan.result))
}

# Helper for known_hosts output - requires ssh-keyscan to be installed on the machine running terraform
data "external" "ssh_keyscan" {
  program = ["bash", "-c", "ssh-keyscan -H ${join(" ", values(aws_instance.managers.*.public_dns))} ${join(" ", values(aws_instance.nodes.*.public_dns))} 2>/dev/null || true"]
}
