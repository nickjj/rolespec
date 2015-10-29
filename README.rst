RoleSpec
========

|Build status|

A shell based test library for Ansible that works both locally and over Travis-CI.

.. contents::
   :local:

Typical Travis setup vs using RoleSpec
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Travis on its own
`````````````````

- Tons of duplication
- Locked into using Travis
- Running bash in YAML syntax
- Manual dependency management
- Tons of "Damn you Travis, please work" commits

RoleSpec
````````
- Still uses Travis, so you can keep the badges and CI environment
- Runs on any Debian-based OS in case you want to use it locally
- Customized assertions optimized for Ansible
- ~75% less code written
- Automatic dependency resolution
- Automatic debug outputs
- Custom linter
- Your test cases end up being fully working examples/documentation
- Multiple test modes to optimize iteration speed

Comparing real examples
~~~~~~~~~~~~~~~~~~~~~~~

The snippets below come from testing a Rails deployment role.

The old typical Travis way
``````````````````````````

.. code:: YAML

  ---

  language: "python"
  python: "2.7"

  env:
    - SITE="tests/main.yml -i 'localhost,'"

  install:
    - "pip install ansible"
    - "printf '[defaults]\\nroles_path = ../' > ansible.cfg"

  before_script:
    - >
      sudo ansible-galaxy install debops.secret debops.etc_services \
      debops.postgresql debops.nginx debops.monit

      git config --global user.email 'foo@bar.com' \
      && git config --global user.name 'Foo Bar'

      cd tests/testapp && git init && cd -

  script:
    - "ansible-playbook $SITE --syntax-check"
    - "ansible-playbook $SITE --connection=local -vvvv"
    - >
      ansible-playbook $SITE --connection=local
      | grep -q "changed=0.*failed=0"
      && (echo "Idempotence test: PASS" && exit 0)
      || (echo "Idempotence test: FAIL" && exit 1)
    - sleep 5
    - >
      sudo cat /srv/users/testapp/.ssh/id_rsa
      | grep -q "ssh"
      && (echo "Private key: PASS" && exit 0)
      || (echo "Private key: FAIL" && exit 1)
    - >
      sudo groups testuser
      | grep -q "audio"
      && (echo "Group: PASS" && exit 0)
      || (echo "Group: FAIL" && exit 1)
    - >
      sudo stat -c "%a %n" /srv/users/testapp
      | grep -q "751"
      && (echo "Secure home: PASS" && exit 0)
      || (echo "Secure home: FAIL" && exit 1)
    - >
      sudo cat /etc/logrotate.d/testapp
      | grep -q "{.*}"
      && (echo "Rotated logs: PASS" && exit 0)
      || (echo "Rotated logs: FAIL" && exit 1)
    - >
      curl -k -s -o /dev/null -w "%{http_code}" https://localhost
      | grep -q "200"
      && (echo "SSL 200 - Testapp: PASS" && exit 0)
      || (echo "SSL 200 - Testapp: FAIL" && exit 1)
    - >
      curl -k -s -o /dev/null -w "%{http_code}" https://localhost/sidekiq
      | grep -q "200"
      && (echo "SSL 200 - Sidekiq: PASS" && exit 0)
      || (echo "SSL 200 - Sidekiq: FAIL" && exit 1)
    - >
      sudo monit status
      | grep -q "testapp"
      && (echo "Monitoring Testapp: PASS" && exit 0)
      || (echo "Monitoring Testapp: FAIL" && exit 1)
    - >
      sudo monit status
      | grep -q "sidekiq"
      && (echo "Monitoring Sidekiq: PASS" && exit 0)
    || (echo "Monitoring Sidekiq: FAIL" && exit 1)


The same test case using RoleSpec
`````````````````````````````````

.. code:: Bash

  #!/bin/bash

  . "${ROLESPEC_LIB}/main"

  install_ansible "v1.7.1"

  cd "${ROLESPEC_TEST}/test_files/testapp" && git init && cd -

  assert_playbook_runs
  assert_playbook_idempotent
  assert_playbook_idempotent_long

  assert_permission "/srv/users/testapp" "751"
  assert_user_in_group "testuser" "audio"

  assert_in_file "/srv/users/testapp/.ssh/id_rsa" "ssh"
  assert_in_file "/etc/logrotate.d/testapp" "{.*}"

  assert_url "https://${ROLESPEC_FQDN}"
  assert_url "https://${ROLESPEC_FQDN}/sidekiq"

  assert_monitoring "testapp"
  assert_monitoring "sidekiq"

Installation
~~~~~~~~~~~~

If you're using it on Travis then you don't need to download anything.

Use this ``.travis.yml`` as a guide, it would go in each of your role's repositories:

.. code:: YAML

  ---

  # Ensure Python 2.7.x is being used
  language: 'python'
  python: '2.7'

  # Use system installed packages inside of the Virtual environment
  virtualenv:
    system_site_packages: True

  # Skip running these which boosts the Travis boot time
  before_install: True
  install: True

  script:
    # Clone the RoleSpec repo, feel free to use --branch xxx to use something
    # other than the master branch (latest stable)
    - 'git clone --depth 1 https://github.com/nickjj/rolespec'

    # The location of YOUR test suite
    - 'cd rolespec ; bin/rolespec -r https://github.com/you/some-test-suite'

You can also use RoleSpec locally, perhaps in a container or virtual machine.

.. code:: Bash

  git clone https://github.com/nickjj/rolespec
  cd rolespec ; sudo make install

Getting setup locally
`````````````````````

You'll probably want to run tests locally in a container or VM so you can
iterate on them quicker. Then once you're ready you could push it out to Travis.
We will go over on how to do this shortly.

Ways to organize your tests
~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Dedicated test suite**

It would consist of 1 repository that contains isolated test cases for each
role you have. This is how we do it for DebOps. Check out the
`DebOps test suite <https://github.com/debops/test-suite>`_ for a working example.

This allows you to not pollute your role's commit history with things like
"Travis is a jerk face, attempt 42 finally worked!". It also makes it
convenient for adding new tests.

**A tests/ directory in each role**

Not supported right now but it could be in the future. I'm looking for feedback
to see if the demand is there. Let me know by opening an issue or by contacting
me, `#debops <http://webchat.freenode.net/?channels=debops>`_ on Freenode
or `@nickjanetakis <https://twitter.com/nickjanetakis>`_.

Write your first test case
~~~~~~~~~~~~~~~~~~~~~~~~~~

Let's create a new test in a container/VM. I'm going to assume by now you have
installed RoleSpec.

First off we'll want to **init a new working directory**. This is where all of
your roles and tests will be stored. It can be located anywhere you want. Run this:

.. code:: Bash

  rolespec -i ~/foo

From this point on I'm going to assume you're in your working directory. All
paths will be relative to that.

For this example let's make pretend we have the following setup:

- Your role name is **foo**
- Your Ansible Galaxy name is **someperson**
- Your role is on GitHub at **github.com/someperson/ansible-foo**
- Your tests are on GitHub at **github.com/someperson/test-suite**
- Your test is located in the **ansible-foo** directory in the **test-suite repo**

**NOTE:** Galaxy and GitHub are not necessary for any of this, it is
just an example.

Let's create a role locally and make it do the least amount possible just so
we can test it.

.. code:: Bash

  mkdir -p roles/someperson.foo/tasks && touch roles/someperson.foo/tasks/main.yml

Basic test scaffold
```````````````````

``rolespec -n tests/ansible-foo`` to create a new test case for this role.

Investigate the hosts file
``````````````````````````

RoleSpec provides you with many variables and will also do find/replaces on
your test to replace placeholders at runtime. The ``hosts`` file is one spot
where you will use a placeholder.

You will notice it contains nothing except ``placeholder_fqdn``. You can put
it in 1 or more groups if you want. All instances of that string will get
swapped to the real fully qualified domain name of the host.

Create a playbook
`````````````````

**You don't have to make one** because RoleSpec will generate one at runtime
for you. It will consist of running the play against the FQDN of the host
(all groups essentially) and set the role you're testing.

If you want more control over the generated playbook then you can supply a
custom playbook of your own, it must be located at ``tests/ansible-foo/playbooks/test.yml``.

Investigate the test
````````````````````

Open up ``tests/ansible-foo/test`` and read through it. It's commented and
explains everything.


Lint it
```````

You can optionally run ``rolespec -l`` to run a linter against all of your
tests. It will report back missing files, warn you if you're missing key things
in your test script/yaml files and perform a syntax check.

- RED results will cause your test to not run
- YELLOW results are warnings that you should fix but are pretty ok to ignore
- No results is great, that means everything is syntactically valid and well formed

Try running it now, you may see some feedback.

Run it
``````

.. code:: Bash

  rolespec -r foo

It should run successfully and you'll be greeted with passing tests at the end.
Here's a cool tip too, if you run ``bash -x rolespec -r foo`` instead you will
be provided with an in depth debug output as it runs.

Test modes
``````````

**By default** RoleSpec will run the full setup/teardown stack. That includes
tasks like installing system packages, installing Ansible, running the
playbook and the assertions. This is good to run when you want to do a full test.

Sometimes you just want to quickly iterate on a playbook and you don't care
about resetting all of the system packages, etc.. You can run RoleSpec
in **playbook mode** like so:

.. code:: Bash

  rolespec -r foo -p

Last up is **turbo mode** which skips everything except running your assertions.
This allows you to work against a static state of the system. Perfect for when
you want to write a bunch of assertions against a known setup. You can
run that like so:

.. code:: Bash

  rolespec -r foo -t

Wrapping things up
``````````````````

If you ever get lost then run ``rolespec -h`` to bring up the help menu. Also
don't forget that each test is basically a standalone guide on how to use your
role. Feel free to use ``inventory/group_vars`` or ``meta/main.yml`` in your
test if you need to.

Example test cases
~~~~~~~~~~~~~~~~~~

You can view over 50 working examples in the
`DebOps test suite <https://github.com/debops/test-suite>`_.

Test API
~~~~~~~~~~~~

System actions
``````````````

Do not use quotes when calling any system functions, they must be passed as
arguments.

- ``install <space separated list of apt packages>``
- ``purge <space separated list of apt packages>``
- ``start <service name>``
- ``stop <service name>``

Ansible actions and assertions
``````````````````````````````

- ``install_ansible [branch=devel]``
    - Installs a specific version of Ansible

You may optionally pass ``ansible-playbook`` arguments to any of the functions
below.

- ``assert_playbook_syntax``
    - Performs just a syntax check
- ``assert_playbook_runs``
    - Performs a syntax check **and** runs the playbook once
- ``assert_playbook_check_runs``
    - Performs a syntax check **and** runs ansible in check mode **and** runs the playbook once
- ``assert_playbook_idempotent``
    - Re-runs the playbook checking for 0 changes
- ``assert_playbook_idempotent_long``
    - Re-runs the playbook checking for 0 changes with periodic output

Basic assertions
````````````````

Add an `!` as an optional last argument to any of the functions below to negate
them.

- ``assert_in <command output or string> <search pattern>``
- ``assert_in_file <path> <search pattern>``
- ``assert_path <path>``
- ``assert_permission <path> <octal permission>``
- ``assert_group <space separated list of groups>``
- ``assert_user_in_group <user> <group>``
- ``assert_running <process name>``
- ``assert_monitoring <process name>``
- ``assert_iptables_allow <port or service name>``
- ``assert_url <full url> [status code=200]``
- ``assert_tcp <hostname> <port> [return code=0]``

Available variables
```````````````````

- ``ROLESPEC_ANSIBLE_INSTALL``
    - The path where Ansible has been installed to
- ``ROLESPEC_ANSIBLE_SOURCE``
    - The address where Ansible has been cloned from
- ``ROLESPEC_ANSIBLE_ROLES``
    - The ``roles_path`` which gets set in ``ansible.cfg``
- ``ROLESPEC_ANSIBLE_CONFIG``
    - The path where ``ansible.cfg`` exists
- ``ROLESPEC_LIB``
    - The path where RoleSpec's libs exist
- ``ROLESPEC_VERSION``
    - The version of RoleSpec
- ``ROLESPEC_RELEASE_NAME``
    - The release name of the host's OS
- ``ROLESPEC_FQDN``
    - The fully qualified domain name of the host
- ``ROLESPEC_TRAVIS``
    - Is the host running on Travis-CI?
- ``ROLESPEC_TRAVIS_ROLES_PATH``
    - The path where roles are downloaded from Travis-CI
- ``ROLESPEC_TURBO_MODE``
    - Has turbo mode been enabled?
- ``ROLESPEC_DEVELOPMENT_MODE``
    - Has development mode been enabled?
- ``ROLESPEC_ROLES``
    - The path where roles are downloaded from Ansible Galaxy
- ``ROLESPEC_ROLE``
    - The name of the role as it exists on the file system
- ``ROLESPEC_ROLE_NAME``
    - The name of the role without any galaxy or repository prefix
- ``ROLESPEC_TEST``
    - The path of the test directory for the current role being tested
- ``ROLESPEC_HOSTS``
    - The path of its hosts file
- ``ROLESPEC_META``
    - The path of its meta file
- ``ROLESPEC_PLAYBOOK``
    - The path of its playbook file
- ``ROLESPEC_SCRIPT``
    - The path of its test file
- ``ROLESPEC_POSTGRESQL_LIBS``
    - A list of packages to purge before installing PostgreSQL
- ``ROLESPEC_MYSQL_LIBS``
    - A list of packages to purge before installing MySQL

Test code style
~~~~~~~~~~~~~~~

Up to you but so far I'm digging this, each section gets separated by 2 lines:

1. Header comments
2. Source the RoleSpec lib
3. Stop service / purge apt packages
4. Install apt packages
5. Any type of setup code that needs to happen before the playbook is ran
6. ``install_ansible [version]``
7. ``assert_playbook_runs`` and optionally ``assert_playbook_idempotent``
8. All of your tests, separated by 0 or 1 lines
9. Any cleanup code that needs to happen, such as stopping a server

Do you want to contribute?
~~~~~~~~~~~~~~~~~~~~~~~~~~

Sounds great, check out the
`contributing guide <https://github.com/nickjj/rolespec/blob/master/CONTRIBUTING.rst>`_
for the details.

Author
~~~~~~

**Nick Janetakis**

- Email: nick.janetakis@gmail.com
- Twitter: `@nickjanetakis <https://twitter.com/nickjanetakis>`_
- GitHub: `nickjj <https://github.com/nickjj>`_

.. |Build status| image:: http://img.shields.io/travis/nickjj/rolespec.svg?style=flat
   :target: https://travis-ci.org/nickjj/rolespec
