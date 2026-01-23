# -*- mode: ruby -*-
# vi: set ft=ruby :

N_WORKERS = 2
MEMORY_CTRL = 2048
MEMORY_WORKER = 4096
CPUS_CTRL = 2
CPUS_WORKER = 2
IP_PREFIX = "192.168.56."
BOX_IMAGE = "bento/ubuntu-24.04"

if ARGV[0] == "up" || ARGV[0] == "provision"
  File.open("inventory.cfg", "w") do |f|
    f.puts "[ctrl]"
    f.puts "ctrl ansible_host=#{IP_PREFIX}100 ansible_ssh_user=vagrant"
    f.puts "\n[workers]"
    (1..N_WORKERS).each do |i|
      f.puts "node-#{i} ansible_host=#{IP_PREFIX}#{100+i} ansible_ssh_user=vagrant"
    end
    f.puts "\n[all:vars]"
    f.puts "ansible_python_interpreter=/usr/bin/python3"
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = BOX_IMAGE
  config.vm.box_version = "202510.26.0"

  # --- Controller VM ---
  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: "#{IP_PREFIX}100"
    
    ctrl.vm.provider "virtualbox" do |v|
      v.name = "ctrl"
      v.memory = MEMORY_CTRL
      v.cpus = CPUS_CTRL
    end

    ctrl.vm.synced_folder "./kubeconfig", "/home/vagrant/.kube", create: true

    ctrl.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/general.yaml"
      ansible.limit = "ctrl"
      ansible.extra_vars = {
        node_ip: "#{IP_PREFIX}100",
        node_name: "ctrl",
        is_worker: false,
        num_workers: N_WORKERS
      }
    end
    
    ctrl.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/ctrl.yaml"
    end
  end

  # --- Worker VMs ---
  (1..N_WORKERS).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      # Dynamic IP Arithmetic 
      node.vm.network "private_network", ip: "#{IP_PREFIX}#{100+i}"

      node.vm.provider "virtualbox" do |v|
        v.name = "node-#{i}"
        v.memory = MEMORY_WORKER
        v.cpus = CPUS_WORKER
      end

      node.vm.provision "shell", inline: <<-SHELL
        mkdir -p /home/vagrant/.ssh
        # Copy the key from the mounted /vagrant directory
        if [ -f /vagrant/.vagrant/machines/ctrl/virtualbox/private_key ]; then
          cp /vagrant/.vagrant/machines/ctrl/virtualbox/private_key /home/vagrant/.ssh/ctrl_key
          chmod 600 /home/vagrant/.ssh/ctrl_key
          chown vagrant:vagrant /home/vagrant/.ssh/ctrl_key
          echo "Controller key copied successfully."
        else
          echo "ERROR: Controller private key not found!"
        fi
      SHELL

      # Provisioning
      node.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "ansible/general.yaml"
        ansible.limit = "node-#{i}"
        ansible.extra_vars = {
          node_ip: "#{IP_PREFIX}#{100+i}",
          node_name: "node-#{i}",
          is_worker: true,
          num_workers: N_WORKERS
        }
      end

      node.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "ansible/node.yaml"
      end
    end
  end
end
