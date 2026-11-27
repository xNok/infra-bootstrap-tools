
COLLECTION_DIR=ansible
COLLECTION_NAME=xnok-infra_bootstrap_tools
DIST_DIR=dist
COLLECTION_TARBALL=$(DIST_DIR)/$(COLLECTION_NAME)-*.tar.gz

.PHONY: up down install-collection clean-collection swarm swarm-up swarm-down swarm-portainer swarm-portainer-caddy k3s k3s-up test-flux-d2 k3s-test

# Build the collection tarball into dist/ if any source file in ansible/ changes
# Excludes the dist/ directory itself to avoid false cache hits
$(DIST_DIR)/$(COLLECTION_NAME)-%.tar.gz: $(shell find $(COLLECTION_DIR) -type f -not -path '*/dist/*')
	mkdir -p $(DIST_DIR)
	cd $(COLLECTION_DIR) && ansible-galaxy collection build --force --output-path ../$(DIST_DIR)

install-collection: $(DIST_DIR)/$(COLLECTION_NAME)-*.tar.gz
	ansible-galaxy collection install --force $<

clean-collection:
	rm -f $(DIST_DIR)/$(COLLECTION_NAME)-*.tar.gz

# Aliases (Backwards Compatibility)
up: swarm-up
down: swarm-down

# Docker Swarm Track
swarm-up: install-collection
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml -e utils_affected_roles_always_run_all_roles=true

swarm-down: install-collection
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml -e utils_affected_roles_always_run_all_roles=true -e terraform_digitalocean_destroy=true

swarm: install-collection
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/docker-swarm.yml

swarm-portainer: install-collection
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/docker-swarm-portainer.yml

swarm-portainer-caddy: install-collection
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/docker-swarm-portainer-caddy.yml

# Kubernetes Track (Dark K3s)
k3s: install-collection
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/k3s.yml

k3s-up: k3s

# Flux D2 / Local Test
test-flux-d2:
	@echo "Ensuring Kind cluster and local registry are running..."
	./bin/k8s/setup-kind-local-registry.sh
	@echo "Running Flux D2 integration test..."
	./bin/tests/flux-d2/test.sh

k3s-test: test-flux-d2

