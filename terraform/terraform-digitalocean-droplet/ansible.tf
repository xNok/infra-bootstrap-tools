/**
 * Gather required information to be able to generate ansible inventory
 *
 */

data "sshclient_host" "nodes" {
  count = length(digitalocean_droplet.nodes)
  hostname = digitalocean_droplet.nodes[count.index].ipv4_address
  username = "keyscan"
  insecure_ignore_host_key = true # we use this to scan and obtain the key
}

data "sshclient_host" "managers" {
  count = length(digitalocean_droplet.managers)
  hostname = digitalocean_droplet.managers[count.index].ipv4_address
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
