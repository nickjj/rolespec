Getting started with Vagrant
============================

- `Quick start`_
- `Creating a Vagrant file`_
- `Adding the provisioning script`_
- `Firing up the vagrant box`_
- `Running tests`_
- `Automating test runs with Guard`_

While TravisCI is pretty cool to check that your roles are fine, you might want
to have a way to test your roles while developing them. This will let you write
your roles in a real TDD fashion. This short guide will help you to set this
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
  curl https://raw.githubusercontent.com/leucos/rolespec/develop/docs/vagrant_specs.sh > vagrant_specs.sh 2>/dev/null
  vagrant up
  vagrant ssh -c specs

Creating a Vagrant file
-----------------------

The required Vagrant file is very basic. It must be in the root directory for
your role. For instance, if you have a ``htop`` role in ``/home/ansible/ansible-htop``,
the Vagrant file path must be ``/home/ansible/ansible-htop/Vagrantfile``.
You might want to adapt it to your needs, but it can boil down to this very 
simple configuration:

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
- copy a shell script to ``/home/vagrant/specs`` and execute it with the 
  arguments provided

Adding the provisioning script
------------------------------

As with the Vagrant file, the provisioning script must sit in your roles's top
directory.

::

  #!/bin/bash
  #
  # Vagrant provisioning script
  #
  # Usage for provisioning VM & running (in Vagrant file):
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

Provisionning the box for the tests
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When the script is called with ``--install``, it will do the following:

- copies itself to ``/usr/local/bin/specs``
- clones rolespec and installs it
- creates a test directory in vagrant's home dir
- creates a symlink for your host role directory in ~/testdir/roles/
- clones your testsuite

Executing the tests
~~~~~~~~~~~~~~~~~~~

When the script is called without any argument, it will launch the tests. Call the script from your host like so:

::

  vagrant ssh -c specs

::

You can also pass regular rolespec arguments, for example turbo mode:

::

  vagrant ssh -c "specs -t"

::

Or may be playbook mode:

::

  vagrant ssh -c "specs -p"

::

Firing up the vagrant box
-------------------------

Now that the required files are there, you just have to start your Vagrant box:

::

  vagrant up

::

The box will be started and provisioned with the provided script.


Running tests
-------------

When the box is up and fully provisioned, running tests is as simple as:

::

  vagrant ssh -c specs

::

Since your role is "mounted" in the Vagrant box, you can just issue this command
whenever your role has changed.

Automating test runs with Guard
-------------------------------

If you want to automate tests runs when you change your role locally, you can
use `Guard <https://github.com/guard/guard/>`_ and 
`guard-shell <https://github.com/guard/guard-shell/>`_.

Guard will execute a command of your choice when some specific files changes.

To give it a try, issue:

::

  gem install guard
  gem install guard-shell

::

Then, in the role's top directory, create a ``Guardfile`` like so;

::

  guard :shell do
    watch(/.*\/.*/) do |m|
      system('vagrant ssh -c "specs -p"')
    end
  end

::

Then start Guard with ``guard``. Now, whenever you change a file in a
subdirectory, Guard will run the tests for you and report back.
