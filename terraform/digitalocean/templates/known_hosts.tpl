%{ for ip in host ~}
${ip} ${key}
%{ endfor ~}