#!/bin/bash

PATH=lib:ext/test-simple-bash/lib:ext/json-bash/lib:$PATH
source test-simple.bash tests 4

GIT_HUB_TEST_MODE="1"
GIT_HUB_CONFIG=$PWD/test/githubconfig

source git-hub
assert-env

cmd="config"
get-options $cmd
get-args config_key config_value
ok [ "=$command=$config_key=$config_value=" == "=config===" ] "$cmd"

cmd="config login"
get-options $cmd
get-args config_key config_value
ok [ "=$command=$config_key=$config_value=" == "=config=login==" ] "$cmd"

cmd="config login pappy"
get-options $cmd
get-args config_key config_value
ok [ "=$command=$config_key=$config_value=" = "=config=login=pappy=" ] "$cmd"

cmd="config-unset login"
get-options $cmd
get-args config_key
ok [ "=$command=$config_key=" = "=config-unset=login=" ] "$cmd"
