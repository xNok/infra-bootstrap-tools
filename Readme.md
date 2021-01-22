# Bootstap your small infra

Features:
* docker-swarm
* Caddy
    * [Auth Portal](https://github.com/greenpau/caddy-auth-portal)
    * [Docker Proxy](https://github.com/lucaslorentz/caddy-docker-proxy)

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

```
ansible-playbook -i inventory/ 1_deploy-caddy/playbook.yml
```

Now you can protect your container behind the caddy auth portal by adding labels in your deployment

```
labels:
    # Add the link of the container to the auth portal
    caddy_0: (ui_links)
    caddy_0.Whoami1: /whoami1
    # Add a route to your container
    ## Domain for your container
    caddy_1: nokwebspace.ovh
    ## Route to access your container
    caddy_1.route: /whoami1*
    ## A snippet is create do add all you need for the route
    caddy_1.route.import: service_route_snippet whoami1
    ## Define who can access that container
    caddy_1.route.jwt.allow: roles user admin superadmin
    ## Define the reverse proxy to point to your container
    caddy_1.route.reverse_proxy: "{{upstreams 80}}"
```

## Alias

Use common infrastructure tools in docker with:
* [docker_tools_alias.sh](./bin/docker_tools_alias.sh)

```
source ./bin/docker_tools_alias.sh
```

```
use dasb for ansible in docker
use dap for ansible-playbook in docker
use daws for awscli in docker
use dpk for packer in docker
use dtf for terraform in docker
use dbash for bash in docker
```