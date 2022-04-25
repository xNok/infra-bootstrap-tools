[nodes]
%{ for ip in nodes_docker_swarm ~}
${ip}
%{ endfor ~}

[managers]
%{ for ip in managers_docker_swarm ~}
${ip}
%{ endfor ~}