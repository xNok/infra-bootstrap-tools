set shell := ["bash", "-c"]

collection_dir := "ansible"
collection_name := "xnok-infra_bootstrap_tools"
dist_dir := "dist"

# Build the Ansible collection tarball into dist/
build-collection:
    mkdir -p {{dist_dir}}
    cd {{collection_dir}} && ansible-galaxy collection build --force --output-path ../{{dist_dir}}

# Install the Ansible collection from the built tarball
install-collection: build-collection
    ansible-galaxy collection install --force {{dist_dir}}/{{collection_name}}-*.tar.gz

# Remove the built Ansible collection tarball
clean-collection:
    rm -f {{dist_dir}}/{{collection_name}}-*.tar.gz

# Deploy infrastructure and run main playbook
up: install-collection
    ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml -e utils_affected_roles_always_run_all_roles=true

# Destroy infrastructure and run main playbook to clean up
down: install-collection
    ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/main.yml -e utils_affected_roles_always_run_all_roles=true -e terraform_digitalocean_destroy=true

# Deploy Docker Swarm
swarm: install-collection
    ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/docker-swarm.yml

# Deploy Docker Swarm with Portainer
swarm-portainer: install-collection
    ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/docker-swarm-portainer.yml

# Deploy Docker Swarm with Portainer and Caddy
swarm-portainer-caddy: install-collection
    ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/docker-swarm-portainer-caddy.yml

# Deploy K3s
k3s: install-collection
    ansible-playbook -i ansible/playbooks/inventory ansible/playbooks/k3s.yml

# Run Flux D2 integration test
test-flux-d2:
    @echo "Ensuring Kind cluster and local registry are running..."
    ./bin/k8s/setup-kind-local-registry.sh
    @echo "Running Flux D2 integration test..."
    ./bin/tests/flux-d2/test.sh
