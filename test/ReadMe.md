git-hub test
============

This document describes how the tests in this directory work.

From the top directory of this repository, you can run:

    make test

or:

    prove test

or:

    prove -v test

The test files end with a '.t' suffix and are written in bash. They use the
`test-more-bash` framework, which is stored under the top level `ext/`
directory. It contains a ReadMe that explains it, as well as its own test
suite.

## `commands.t`

This test runs `git hub` commands that have been mocked up. They don't
actually call to the GitHub server. They use cached data responses. New
command tests are created like this:

    GIT_DIR=test/repo/drinkup/ test/bin/make-command-test 'git hub <command>'

The `GIT_DIR` variable must be set to one of the fake repos under
`test/repo/`.  This is the context repo under which the command is run, since
git-hub is always aware of its repo context.

The test data is stored under `test/commands/<command>`, and contains the
stdout and stderr from the command. It also contains all the API call
responses, which are stored under sha1 disrectories.
