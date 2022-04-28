[nodes]
%{ for ip in nodes ~}
${ip} ansible_user=root
%{ endfor ~}

[managers]
%{ for ip in managers ~}
${ip} ansible_user=root
%{ endfor ~}