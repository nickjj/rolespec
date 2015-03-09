Getting started with Vagrant
============================

- `Quick start`_
- `Creating a Vagrant file`_
- `Adding the provisionning script`_
- `Firing up the vagrant box`_
- `Running tests`_
- `Example`_

While TravisCI is pretty cool to check that your roles are fine, you might want
to have a way to test your roles while developping them. This will let you write
your roles in a real TDD fashion. This short guide will help you setting this
up.

Quick start
-----------
::

  cd path/to/your_role
  cat > Vagrantfile << EOF
  Vagrant.configure(2) do |config|
    config.vm.box = "ubuntu/trusty64"
  
    config.vm.provision "shell",
      :path => "vagrant_specs.sh",
      :upload_path => "/home/vagrant/specs",
      # change <your_role> and <specs_repos> below
      :args => "--install <your_role> <specs_repos>"
  end
  EOF
  curl https://raw.githubusercontent.com/leucos/rolespec/develop/docs/vagrant_specs.sh > vagrant_specs.sh
  vagrant up
  vagrant ssh -c specs

Creating a Vagrant file
-----------------------

The required Vagrant file is very basic. It must be in the root directory for
your role. For instance, if you have a ``htop`` role in ``/home/ansible/ansible-
htop``, the Vagrant file path must be ``/home/ansible/ansible-
htop/Vagrantfile``. You might want to adapt it to your needs, but it can boil
down to this very simple configuration:

::

  # -*- mode: ruby -*-
  # vi: set ft=ruby :
  
  Vagrant.configure(2) do |config|
    config.vm.box = "ubuntu/trusty64"
  
    config.vm.provision "shell",
      :path => "vagrant_specs.sh",
      :upload_path => "/home/vagrant/specs",
      :args => "--install <role_name> <specs_repos>"
  end

::

You have to change the arguments in the args line:
- ``role_name``: set your current role name 
- ``specs_repos``: your tests repository URL

This file will:

- download and boot a ubuntu/trusty64 vagrant image
- copy a shell script to "/home/vagrant/specs" and execute it with the arguments
  provided

Adding the provisionning script
-------------------------------

As with the Vagrant file, the provisioning script must sit in your roles's top
directory.

::

  #!/bin/bash
  #
  # Vagrant provisionning script
  #
  # Usage for provisionning VM & running (in Vagrant file):
  # 
  # script.sh --install <role> <URL for test suite>
  #
  # e.g. : 
  # script.sh --install ansible-nginx https://github.com/erasme/erasme-roles-specs.git
  # 
  # Usage for running only (from host):
  #
  # vagrant ssh -c ./specs
  #
  if [ "x$1" == "x--install" ]; then
    cp ~vagrant/specs /usr/local/bin/specs
    chmod 755 /usr/local/bin/specs
    su vagrant -c 'git clone --depth 1 https://github.com/nickjj/rolespec'
    cd ~vagrant/rolespec && make install
    su vagrant -c 'rolespec -i ~/testdir'
    su vagrant -c "ln -s /vagrant/ ~/testdir/roles/$2"
    su vagrant -c "git clone $3 ~/testdir/tests"
    exit
  fi
  
  cd ~vagrant/testdir && rolespec -r $(ls roles) "$*"

::

This script serves two purposes:

Setting up the box for the test
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When the script is called with ``--install``, it will do the following:

- copies itself to ``/usr/local/bin/specs``
- clones rolespec and installs it
- creates a test directory in vagrant's home dir
- creates a symlink for your host role directory in ~/testdir/roles/
- clones your testsuite

Executing the tests
~~~~~~~~~~~~~~~~~~~

When the script is called without any argument, it will launch the tests. To
call the script from the host, you just have to issue:

::

  vagrant ss -c specs

::

you can also pass regular rolespec arguments, e.g.:

::

  vagrant ssh -c specs -t

::

for turbo mode.

Firing up the vagrant box
-------------------------

Now that the required files are there, you just have to start your Vagrant box:

::

  vagrant up

::

The box will be started and provisionned with the provided script.


Running tests
-------------

When the box is up and fully provisionned, running tests is as simple as:

::

  vagrant ssh -c specs

::

Since you role is "mounted" in the Vgrant box, you can just issue this command
whenever your role has changed.

You can even run Guard to continuously trigger tests when the role changes. Here is a sample Guardfile:

::

  guard :specs, cmd: 'vagrant ssh -c specs' do
    watch(%r{^defaults/.*$})
    watch(%r{^tasks/.*$})
    watch(%r{^templates/.*$})
  end

::
