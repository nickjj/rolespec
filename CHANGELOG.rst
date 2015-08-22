RoleSpec changelog
==================

v0.3.3 / 2015-08-22
~~~~~~~~~~~~~~~~~~~

- Add separate assertion to run the Ansible playbook in "dry mode" before
  executing the real playbook. This is done so that ``ansible-playbook --check
  --diff`` mode can be tested for errors as well. The old version fo the
  assertion is still available.

v0.3.2 / 2014-09-19
~~~~~~~~~~~~~~~~~~~

- Fix the test harness from exiting with 1

v0.3.1 / 2014-09-19
~~~~~~~~~~~~~~~~~~~

- Fix a bug in the test harness (does not affect RoleSpec itself)

v0.3.0 / 2014-09-19
~~~~~~~~~~~~~~~~~~~

- Remove the ferm dependency on ``assert_iptables_allow``
- Add ``start`` system action to start processes
- Add documentation for ``install_ansible``
- Add Travis-CI to RoleSpec itself
- Add a test harness to test RoleSpec itself

v0.1.0 / 2014-09-18
~~~~~~~~~~~~~~~~~~~

- First release of RoleSpec
