%{ for k, v in known_hosts ~}
${ k } ${v}
%{ endfor ~}