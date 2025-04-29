
up:
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml -e utils_affected_roles_always_run_all_roles=true

down:
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml -e terraform_digitalocean_destroy=true
