%{ for k, v in keyscan ~}
${k} ${v.authorized_key}
%{ endfor ~}