[nodes]
%{ for index, ip in nodes ~}
${prefix}-node-${index} ansible_host=${ip} ansible_user=${user}
%{ endfor ~}

[managers]
%{ for index, ip in managers ~}
${prefix}-manager-${index} ansible_host=${ip} ansible_user=${user}
%{ endfor ~}