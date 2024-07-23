# Startup Infra for Small Self-hosted Projects

![Ansible](https://img.shields.io/badge/ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=white) ![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white) ![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white) ![Vagrant](https://img.shields.io/badge/vagrant-%231563FF.svg?style=for-the-badge&logo=vagrant&logoColor=white) ![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)

This repository provides Ansible playbooks to set up a minimal infrastructure for a simple self-hosted application. Ideal for small hobby projects. I made this repository a place to **Learn** about DevOps and Cloud Infrastructure. You have all the tutorial you need to get started.

Features:
* docker-swarm
* Caddy
* Portainer
* Prometheus 
* Graphana

## Articles and Tutorials

The article / tutorial are splited into sections. 
* **Introduction** -> What are the tools to use to manager infrastructure. Perfect to learn the basis.
* **How-tos** -> Good take away fron this project - Answers many questions you could encounter in the future
* **Main quest** -> Deploy the Infrastructure using Ansible, Terraform and Github Action
* **Deepening Understanding** -> learn more about each applicaton used in this setup (Portainer, Graphana, Caddy, etc.)

### Tools Introduction

* [ ] WIP: 📚 1: [What is **Terraform** and why you might need it.]()
* [X] 📚 2: [What is **Terraform Cloud** and why you might need it.](https://faun.pub/what-is-terraform-cloud-and-why-you-might-need-it-c9847fb8f6e6?sk=ee85423512f39030bb287a3f2a6623d3)
* [ ] WIP: 📚 3: [What is **Github Action** and why you might need it.]()
* [ ] WIP: 📚 4: [What is **Ansible** and why you might need it.]()
* [ ] WIP: 📚 5: [What is **Ansible AWX** and why you might need it.]()

### Learn the Tools

* [X] 🌍 [How to configure GitHub Environments with Terraform?](https://faun.pub/how-to-configure-github-environments-with-terraform-d2b76766547b?sk=b50616eed7da268d5a99c459fc9c57d5)
* [x] 🏭 [How to provision VM on Digital Ocean with Terraform?](https://faun.pub/how-to-provision-vms-on-digitalocean-with-terraform-898515a0dbbc?sk=7af174d77b4a7bd81e581378beac9a0d)
* [X] 🔏 [How to create SSH keys with Terraform?](https://faun.pub/how-to-create-ssh-keys-with-terraform-a615dfc631c1?sk=176a8f5c0c0517a01e8fabd5bb7c18fa)
* [x] 🗺️ [How to create Ansible Inventory with Terraform?](https://faun.pub/how-to-create-ansible-inventory-with-terraform-a32fcbe11be6?sk=da18fba15ee996e4c3b92782229654ee)
* [x] 👩 [How to run an Ansible playbook using GitHub Action?](https://faun.pub/how-to-run-an-ansible-playbook-using-github-action-42430dec944?sk=7796e8bd44f6b8c394b80507b8ff3e87)

### Main Quest - Put it all together

* [X] 🧰 1: [Design and Test Ansible playbook with Vagrant](https://faun.pub/a-disposable-local-test-environment-is-essential-for-devops-sysadmin-af97fa8f3db0?sk=f2f0e3a6b4fe4215cec13019887b6302)
   * Example code [.articles/1_vagrant_101](.articles/1_vagrant_101)   
* [X] 🧰 2 [Experimenting on Docker Swarm with Vagrant and Ansible](https://faun.pub/experimenting-on-docker-swarm-with-vagrant-and-ansible-bcc2c79ba7c4?sk=1eac227cf3c9ec5dc5abbf06f38e92c3)
   * Example code [.articles/2_docker_swarm_101](.articles/2_docker_swarm_101)
* [ ] WIP: 🧰 3: [Automate Infrastructure provisioning with Ansible and Github action]()

### Learn about the applications used in this setup

* [ ] WIP: ☸️ 1: [What is Portainer and why you might need it.]()
* [ ] WIP: ☸️ 2: [What is Prometheus and why you might need it.]()
* [ ] WIP: ☸️ 3: [What is Caddy and why you might need it.]()

### Deep Dives

Below, I've included some explainers on how I solved a specific problem when I encountered it. This should demistify some of the magic happening in this repo.

#### Ansible

* [x] 🏃‍♂️ 1: [Speedup Ansible Playbook Pull-Requests by only running affected roles](https://medium.com/itnext/speedup-ansible-playbook-merge-request-by-only-running-affected-roles-42d9ca3f6433?sk=382b8de777e41deb20f7fefe430b2f26)
* [ ] WIP 🏃‍♂️ 2: [How to rotate Docker Secrets with Ansible]()
* [ ] WIP 🏃‍♂️ 3: [How to implement Pull-Request locking for Ansible]()

## Architecture

![](./diagrams/startup_infra_for_small_self_hosted_project.png)

## Handy toolchain

Do you want to go fast? Too lazy to set up your local environment?

Then, use the tools from a Docker container. I included a simple Toochain in this repository and a useful alias for it.

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

## Scale Up

With docker swarm and portainer it because easy to manager multiple nodes.

![](./diagrams/scaled_up_infra_for_small_self_hosted_project.png)
