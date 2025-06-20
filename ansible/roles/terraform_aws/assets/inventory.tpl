# Ansible Inventory for AWS

[managers]
{% for ip in managers %}
{{ prefix }}-manager-{{ loop.index }} ansible_host={{ ip }} ansible_user={{ user }}
{% endfor %}

[nodes]
{% for ip in nodes %}
{{ prefix }}-node-{{ loop.index }} ansible_host={{ ip }} ansible_user={{ user }}
{% endfor %}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
