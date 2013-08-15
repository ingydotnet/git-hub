#!/bin/bash

PATH=lib:ext/test-simple-bash/lib:ext/json-bash/lib:$PATH
source test-simple.bash tests 1

GIT_HUB_TEST_COMMAND="1"
GIT_HUB_CONFIG=$PWD/test/githubconfig

source $PWD/lib/git-hub
GitHub.assert-env

command_arguments=(login)
ok [ $(GitHub.config) == tommy ] "Reading login form config works"
