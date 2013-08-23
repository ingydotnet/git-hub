#!/bin/bash

PATH=ext/test-simple-bash/lib:$PATH
source test-simple.bash tests 1

GIT_HUB_TEST_COMMAND="1"
GIT_HUB_CONFIG=$PWD/test/githubconfig
PATH=lib:$PATH
source git-hub
init-env

command_arguments=(login)
ok [ $(command:config) == tommy ] "Reading login form config works"
