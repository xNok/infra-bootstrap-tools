[nodes]
%{ for ip in nodes ~}
${ip}
%{ endfor ~}

[managers]
%{ for ip in managers ~}
${ip}
%{ endfor ~}