#!/bin/bash

set -e

source $PWD/ext/bash-tap/bash-tap
# plan tests 2

GIT_HUB_TEST_MODE="1"
GIT_HUB_CONFIG=$PWD/test/githubconfig

source $PWD/lib/git-hub
assert-env

cmd="config"
get-options $cmd
get-args config_key config_value
is "|$command|$config_key|$config_value|" "|config|||" "$cmd"

cmd="config login"
get-options $cmd
get-args config_key config_value
is "|$command|$config_key|$config_value|" "|config|login||" "$cmd"

cmd="config login pappy"
get-options $cmd
get-args config_key config_value
is "|$command|$config_key|$config_value|" "|config|login|pappy|" "$cmd"

cmd="config-unset login"
get-options $cmd
get-args config_key
is "|$command|$config_key|" "|config-unset|login|" "$cmd"

done_testing
