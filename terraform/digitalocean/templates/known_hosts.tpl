%{ for ip in host ~}
${ip} ${algorithm} ${fingerprint}
%{ endfor ~}