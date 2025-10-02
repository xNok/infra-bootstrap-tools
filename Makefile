
COLLECTION_DIR=ansible
COLLECTION_NAME=xnok-infra_bootstrap_tools
COLLECTION_TARBALL=$(COLLECTION_DIR)/$(COLLECTION_NAME)-*.tar.gz

.PHONY: up down install-collection

# Build the collection tarball if any file in the collection dir changes
$(COLLECTION_DIR)/$(COLLECTION_NAME)-*.tar.gz: $(shell find $(COLLECTION_DIR) -type f)
	cd $(COLLECTION_DIR) && ansible-galaxy collection build --force

install-collection: $(COLLECTION_DIR)/$(COLLECTION_NAME)-*.tar.gz
	ansible-galaxy collection install --force $<

up: install-collection
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml -e utils_affected_roles_always_run_all_roles=true

down: install-collection
	ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml -e terraform_digitalocean_destroy=true
