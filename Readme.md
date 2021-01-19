
##

## Setup host

Setup machine after recieving it.

### 1. Add ssh key

```
ansible-playbook 0_setup_host/password-less-ssh/playbook.yml
```

### 2. Install docker

```
ansible-playbook -i inventory/ 0_setup_host/install-docker/playbook.yml
```

### 3. Init docker swarm

```
ansible-playbook -i inventory/ 0_setup_host/init-docker-swarm/playbook.yml
```

## Setup Security

### 1. Caddy reverse proxy


## Alias

Use common infrastructure tools in docker with:
* [docker_tools_alias.sh](./bin/docker_tools_alias.sh)