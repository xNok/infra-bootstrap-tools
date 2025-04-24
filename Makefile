
up:
	ansible-playbook -i ansible/inventory ansible/main.yml -e always_run_all_roles=true

down:
	ansible-playbook -i ansible/inventory ansible/main.yml -e terraform_destroy=true
