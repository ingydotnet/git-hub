#!/bin/bash

# set -ex

PATH=ext/test-simple-bash/lib:$PATH
source test-simple.bash tests 4

GIT_HUB_CONFIG=$PWD/test/githubconfig
PATH=lib:$PATH
source git-hub
init-env

cmd="config"
get-opts $cmd
Get-args config_key config_value
ok [ "=$command=$config_key=$config_value=" == "=config===" ] "$cmd"

cmd="config login"
get-opts $cmd
Get-args config_key config_value
ok [ "=$command=$config_key=$config_value=" == "=config=login==" ] "$cmd"

cmd="config login pappy"
get-opts $cmd
Get-args config_key config_value
ok [ "=$command=$config_key=$config_value=" = "=config=login=pappy=" ] "$cmd"

cmd="config-unset login"
get-opts $cmd
Get-args config_key
ok [ "=$command=$config_key=" = "=config-unset=login=" ] "$cmd"
