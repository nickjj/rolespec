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
    if [[ -x '/usr/bin/apt-get' ]]; then
      sudo apt-get install -qqy git
    else
      sudo yum install -q -y git
    fi
    su vagrant -c 'git clone --depth 1 https://github.com/nickjj/rolespec'
    cd ~vagrant/rolespec && make install
    su vagrant -c 'rolespec -i ~/testdir'
    su vagrant -c "ln -s /vagrant/ ~/testdir/roles/$2"
    su vagrant -c "git clone $3 ~/testdir/tests"
    exit
  fi

# if [ "x$1" == "x--galaxy" ]; then
#   # Remove anything below ~/testdir/roles
#   su vagrant -c "rm "
# else

# fi

cd ~vagrant/testdir && rolespec -r $(ls roles) "$*"
