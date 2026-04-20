# Ansible Inventory for AWS

[{{ managers_group }}]
{% for ip in managers %}
{{ prefix }}-manager-{{ loop.index }} ansible_host={{ ip }} ansible_user={{ user }}
{% endfor %}

[{{ nodes_group }}]
{% for ip in nodes %}
{{ prefix }}-node-{{ loop.index }} ansible_host={{ ip }} ansible_user={{ user }}
{% endfor %}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
