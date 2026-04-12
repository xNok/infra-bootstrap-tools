---
title: "Design and Test Ansible Playbooks with Vagrant"
date: 2023-11-20
author: xNok
summary: A disposable local test environment is essential for DevOps. Learn how to use Vagrant to safely test Ansible playbooks before production deployment.
canonical_url: https://faun.pub/a-disposable-local-test-environment-is-essential-for-devops-sysadmin-af97fa8f3db0
tags:
  - Ansible
  - Vagrant
  - DevOps
  - Testing
  - Infrastructure as Code
---

Working on your infrastructure setups and testing your automation script can be tedious if you don’t have a proper test environment that enables a fast iteration loop. The best when automating your server provisioning with [Ansible ](https://www.ansible.com/)scripts is to be able to set up servers a local server step by step then play all the steps from the ground up and make sure everything goes as planned. Once the local and iterative design phase is complete you will be ready to create an automated pipeline to set up an actual production environment.
Why Ansible you may ask? Ansible is simple and easy to learn if you have some Linux administration knowledge. We are configuring a Linux server after all you can’t escape that part.
With a small project spread across several articles, I want to show you what I consider the minimum requirement for a small self-hosted project. I invite you to check my [Github repository](https://github.com/xNok/infra-bootstrap-tools) for other articles and more details about the whole project.
In this article, you will see how to get started and set up a local testing environment. You will learn about [Vagrant ](https://www.vagrantup.com/)a tool to create local virtual machines on the fly.
## Getting Started with Vagrant
First, install Vagrant. Simply go to the [main page](https://www.vagrantup.com/) and download the product for your platform. Once Vagrant is installed you can need a hypervisor, the most popular is VirtualBox because it can run on Linux, Windows, and Mac OS. With both requirements installed (Vagrant + VirtualBox) you can get started spawning a Linux Debian** **virtual machine and start experimenting.
To create a VM, you need to understand the Concept of a [Vagrant Box](https://www.vagrantup.com/docs/boxes). Put simply Boxes is the way Vagrant packages environments so they can be shared via a registry such as [Vagrant Cloud](https://app.vagrantup.com/boxes/search). Let’s search for a Debian box that fit your need. This one should do the job: [generic/debian10](https://app.vagrantup.com/generic/boxes/debian10)
Two steps to getting your box running:
```bash
vagrant init generic/debian10
vagrant up
```
The first command created a file called [Vagrantfile](https://www.vagrantup.com/docs/vagrantfile) that describes how to provision your environment. The file created with the `init` command simply specifies that we want to use the Vagrant box [**generic/debian10**](https://app.vagrantup.com/generic/boxes/debian10) as a base.
```ruby
Vagrant.configure("2") do |config|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "generic/debian10"
end
```
The second command `vagrant up` starts and provision the VM. Once your box is running you can SSH into and play with it.
```bash
vagrant ssh
```
At that point, you could start making procedures about how to install everything you need. But this approach would no be to be maintainable and reproducible. This is why you need to also learn about Vagrant [provisioner](https://www.vagrantup.com/docs/provisioning)s.
## Vagrant and Ansible
[Ansible](https://github.com/ansible/ansible) is a simple automation tool that can orchestrate pretty much any task you would need to configure and maintain your infrastructure. Ansible work best when you are dealing with actual machines (servers or virtual machines), I would not recommend using it to provision Cloud infrastructure as it lacks a state management capabilities you can find in other tools such as [Terraform](https://www.terraform.io/). But here we will be dealing with configuring Linux servers so ansible works best here.
In order to make the bridge between Vagrant and Ansible, you will use the [Ansible ](https://www.vagrantup.com/docs/provisioning/ansible_common)[*Provisioners*](https://www.vagrantup.com/docs/provisioning/ansible_common)*. *Provisioners are tools that vagrant will use to set up your virtual machine and Vagrant support the most command tools on the market and offers the ability to create your own provisioner to meet your needs. But let’s focus on the [Ansible Local Provisioner](https://www.vagrantup.com/docs/provisioning/ansible_local), that way you don’t even have to worry about installing Ansible on your local machine Vagrant will install it inside your virtual machine.
```ruby
Vagrant.configure("2") do |config|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "generic/debian10"

	# The Ansible Local provisioner requires that all the Ansible Playbook files are available on the guest machine
  config.vm.synced_folder ".", "/vagrant"

  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "playbook.yml"
  end
end
```
Vagrant makes it easy for you to run your ansible provisioning scripts against the virtual machine it created for you. You should see a folder `.vagrant` at the root of your project (this folder should be ignored by git, if not add it to your .`gitignore`). 
Next you need to create an “hello-world” playbook called `playbook.yaml`:
```yaml
- name: This is a hello-world example
  hosts: all
  tasks:
    - name: Create a file called '/tmp/testfile.txt' with the content 'hello world'.
      copy:
        content: hello-world
        dest: /tmp/testfilprovisioning
```
You are ready to try out your first ansible provisioning with Vagrant
```yaml
$ Vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'generic/debian10' version '3.6.8' is up to date...
==> default: Clearing any previously set forwarded ports...
==> default: Fixed port collision for 22 => 2222. Now on port 2200.
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 22 (guest) => 2200 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2200
    default: SSH username: vagrant
    default: SSH auth method: private key
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
==> default: Mounting shared folders...
    default: /vagrant => E:/Nokwebspace/infra-bootstrap-tools
==> default: Running provisioner: ansible_local...
    default: Installing Ansible...
    default: Running ansible-playbook...

PLAY [This is a hello-world example] *******************************************

TASK [Gathering Facts] *********************************************************
ok: [default]

TASK [Create a file called '/tmp/testfile.txt' with the content 'hello world'.] ***
changed: [default]

PLAY RECAP *********************************************************************
default                    : ok=2    changed=1    unreachable=0    failed=0
```
If you make changes to the playbook you can simply run only the provisioning stage
```yaml
vagrant provision
```
Once you are done or want to take a break simply stop the VM.
```yaml
vagrant halt
```
## Conclusion
You are ready to start working on your next infrastructure provisioning project. Having a disposable test environment is essential and Vagrant will soon become your favorite tool. 
You can check my Github repository [https://github.com/xNok/infra-bootstrap-tools](https://github.com/xNok/infra-bootstrap-tools) to find more tutorials and build the following infrastructure.
![](/images/blog/automating-ssl-caddy_d22af972ed.png)
