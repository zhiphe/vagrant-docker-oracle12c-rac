# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don"t touch unless you know what you"re doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "oraclelinux65"

  # vm nodes
  config.vm.define :node do |node|
    node.vm.hostname = "node"
    node.vm.provider :virtualbox do |vb|
      vb.memory = 4096
      vb.customize ["createhd", "--filename", "asm.vdi", "--size", 10*1024, "--variant", "fixed"]
      vb.customize ["createhd", "--filename", "opt1.vdi", "--size", 15*1024, "--variant", "fixed"]
      vb.customize ["createhd", "--filename", "opt2.vdi", "--size", 15*1024, "--variant", "fixed"]
      vb.customize ["storageattach", :id, "--storagectl", "SATA", "--port", 1, "--device", 0, "--type", "hdd", "--medium", "asm.vdi"]
      vb.customize ["storageattach", :id, "--storagectl", "SATA", "--port", 2, "--device", 0, "--type", "hdd", "--medium", "opt1.vdi"]
      vb.customize ["storageattach", :id, "--storagectl", "SATA", "--port", 3, "--device", 0, "--type", "hdd", "--medium", "opt2.vdi"]
      # required for pipework
      vb.customize ['modifyvm', :id, '--nicpromisc1', 'allow-all']
    end
  end

  # run setup.sh
  config.vm.provision "shell", path: "setup_host.sh"

  # proxy
  #config.proxy.http     = "http://proxy:80"
  #config.proxy.https    = "http://proxy:80"
  #config.proxy.no_proxy = "localhost,127.0.0.1"
end
