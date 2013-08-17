#!/bin/bash

PATH=ext/test-simple-bash/lib:$PATH
source test-simple.bash tests 1

GIT_HUB_TEST_COMMAND="1"
GIT_HUB_CONFIG=$PWD/test/githubconfig
PATH=lib:$PATH
source git-hub
GitHub.init-env

command_arguments=(login)
ok [ $(GitHub.config) == tommy ] "Reading login form config works"
