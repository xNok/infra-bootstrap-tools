
##

## Setup host

Setup machine after recieving it.

### 1. Add ssh key

```
ansible-playbook ansible-playbooks/password-less-ssh/playbook.yml
```

### 2. Install docker

```
ansible-playbook -i inventory/ ansible-playbooks/install-docker/playbook.yml
```

## Setup Security

### 1. Caddy reverse proxy


## Alias

Use common infrastructure tools in docker with:
* [docker_tools_alias.sh](./bin/docker_tools_alias.sh)