
gen_diagrams:
	cat diagrams/base_architecture.py | docker run -i --rm -v ${PWD}/diagrams:/out gtramontina/diagrams:0.19.1
	cat diagrams/scaled_up_architecture.py | docker run -i --rm -v ${PWD}/diagrams:/out gtramontina/diagrams:0.19.1

tools:
	. ./bin/docker_tools_alias.sh

up:
	ansible-playbook -i ansible/inventory ansible/full.yml

down:
	ansible-playbook -i ansible/inventory ansible/full.yml -e terraform_destroy=true
