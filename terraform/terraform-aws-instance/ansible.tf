/**
 * Gather required information to be able to generate ansible inventory
 *
 */

data "sshclient_host" "nodes" {
  count = length(aws_instance.nodes)
  hostname = aws_instance.nodes[count.index].public_ip
  username = "keyscan"
  insecure_ignore_host_key = true # we use this to scan and obtain the key
}

data "sshclient_host" "managers" {
  count = length(aws_instance.managers)
  hostname = aws_instance.managers[count.index].public_ip
  username = "keyscan"
  insecure_ignore_host_key = true # we use this to scan and obtain the key
}

data "sshclient_keyscan" "keyscan_nodes" {
  count  = length(data.sshclient_host.nodes)
  host_json = data.sshclient_host.nodes[count.index].json
}

data "sshclient_keyscan" "keyscan_managers" {
  count  = length(data.sshclient_host.managers)
  host_json = data.sshclient_host.managers[count.index].json
}

locals {
  known_hosts = merge(
    {for k, v in data.sshclient_host.nodes : v.hostname => data.sshclient_keyscan.keyscan_nodes[k].authorized_key },
    {for k, v in data.sshclient_host.managers : v.hostname => data.sshclient_keyscan.keyscan_managers[k].authorized_key },
  )
}
