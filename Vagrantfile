# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "generic/debian10"

  # We are moving to a more complex example so to avoid issues we will limit the RAM of each VM
  config.vm.provider "virtualbox" do |v|
    v.memory = 512
  end
  
  #########
  # Nodes: host our apps 
  #########

  config.vm.define "node1" do |node|
    node.vm.network "private_network", ip: "172.17.177.21"
  end

  config.vm.define "node2" do |node|
    node.vm.network "private_network", ip: "172.17.177.22"
  end

  #########
  # Controller: host our tools
  #########
  config.vm.define 'controller' do |machine|

    # The Ansible Local provisioner requires that all the Ansible Playbook files are available on the guest machine
    machine.vm.synced_folder ".", "/vagrant",
       owner: "vagrant", group: "vagrant", mount_options: ["dmode=755,fmode=600"]
    
    machine.vm.network "private_network", ip: "172.17.177.11"

    machine.vm.provision "ansible_local" do |ansible|
      ansible.playbook       = "ansible/hello-world.yml"
      ansible.verbose        = true
      ansible.install        = true
      ansible.limit          = "all" # or only "nodes" group, etc.
      ansible.inventory_path = "inventory"
    end
  end
end