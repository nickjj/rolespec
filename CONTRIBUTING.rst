Contributing guidelines
=======================

- `Issue reporting`_
- `Code submissions`_
- `Code style`_
- `License agreement`_

Issue reporting
~~~~~~~~~~~~~~~

RoleSpec is officially hosted on GitHub at https://github.com/nickjj/rolespec.

Please report all issues to the `nickjj/rolespec issue tracker <https://github.com/nickjj/rolespec/issues>`_.

Code submissions
~~~~~~~~~~~~~~~~

RoleSpec follows the `git flow model <http://nvie.com/posts/a-successful-git-branching-model/>`_.
Here's a quick work flow for a `pull request <https://help.github.com/articles/using-pull-requests>`_:

Fork it
-------

- `Fork it <https://github.com/nickjj/rolespec/fork>`_ into your GitHub account
- ``git clone git@github.com:YOURACCOUNT/rolespec.git``
- ``git remote add upstream https://github.com/nickjj/rolespec``

Make your contribution
----------------------

::

    git checkout develop
    git checkout -b feature-branch
    git add <the files you modified>
    git push origin feature-branch

Try your best to make great commit messages. Check out
`better commits <http://web-design-weekly.com/2013/09/01/a-better-git-commit>`_
and use ``git add -p``.

Submit your pull request through GitHub
```````````````````````````````````````

Select the branch on your fork, click the green PR button and submit it.

Keep your fork updated
``````````````````````

You should do this before making any commits and after your PR has been accepted.

::

    git checkout develop
    git fetch upstream
    git rebase upstream/develop
    git push origin develop

Code style
~~~~~~~~~~

- Try your best to stay under 80 characters per line but don't go crazy trying
- 2 space indentation for everything unless noted otherwise
- Comments and output start with a capital letter and have no periods


License agreement
~~~~~~~~~~~~~~~~~

By contributing you agree that these contributions are your own
(or approved by your employer) and you grant a full, complete, irrevocable
copyright license to all users and developers of the project, present and
future, pursuant to the license of the project.
