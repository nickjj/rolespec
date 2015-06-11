# -*- mode: ruby -*-
# vi: set ft=ruby :
$debian = <<DEBIAN
# sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update
# sudo apt-get install -qy ansible
sudo apt-get install -qy git
(cd /vagrant && sudo make test)
DEBIAN

$centos = <<CENTOS
sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
sudo yum install -y git
(cd /vagrant && sudo make test)
CENTOS

Vagrant.configure(2) do |config|
  config.vm.define "debian", autostart: false do |deb|
    deb.vm.box = "debian/jessie64"
    deb.vm.provision "shell", inline: $debian
  end

  config.vm.define "centos", autostart: false do |centos|
    centos.vm.box = "chef/centos-6.6"
    centos.vm.provision "shell", inline: $centos
  end
end
