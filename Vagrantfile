# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

	config.vm.box = "bento/ubuntu-24.04"
	config.vm.box_version = "202510.26.0"
	
  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: "192.168.56.100"
    ctrl.vm.provider "virtualbox" do |v|
      v.name = "ctrl"      
      v.memory = 4096       
      v.cpus = 2
    end
    ctrl.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/ctrl.yaml"
    end

  end

  config.vm.define "node-1" do |node|
    node.vm.hostname = "node-1"
    node.vm.network "private_network", ip: "192.168.56.101"
    node.vm.provider "virtualbox" do |v|
      v.name = "node-1"   
      v.memory = 6144       
      v.cpus = 2
    end
    node.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/node.yaml"
    end
  end

  config.vm.define "node-2" do |node|
    node.vm.network "private_network", ip: "192.168.56.102"
    node.vm.hostname = "node-2"
    node.vm.provider "virtualbox" do |v|
      v.name = "node-2"     
      v.memory = 6144      
      v.cpus = 2
    end
    node.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/node.yaml"
    end
  end

	config.vm.provision :ansible do |a|
   		a.compatibility_mode = "2.0"
   		a.playbook = "general.yaml"
	end

end