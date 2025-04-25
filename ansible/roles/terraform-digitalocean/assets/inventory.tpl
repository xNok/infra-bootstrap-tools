[nodes]
{% for ip in nodes %}
{{ prefix }}-node-{{ loop.index0 }} ansible_host={{ ip }} ansible_user={{ user }}
{% endfor %}

[managers]
{% for ip in managers %}
{{ prefix }}-manager-{{ loop.index0 }} ansible_host={{ ip }} ansible_user={{ user }}
{% endfor %}