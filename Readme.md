
##

## Ansible


Setup machine after recieving it.

### Add ssh key

```
ansible-playbook ansible-playbooks/password-less-ssh/playbook.yml
```

### Use ssh key locally

```
ssh-agent bash
ssh-add ~/.ssh/infra_rsa
```



## Alias

Use common infrastructure tools in docker with:
* [docker_tools_alias.sh](./bin/docker_tools_alias.sh)