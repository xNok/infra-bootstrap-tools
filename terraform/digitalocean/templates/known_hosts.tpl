%{ for k, v in keyscan ~}
${ hostname[k] } ${v.authorized_key}
%{ endfor ~}