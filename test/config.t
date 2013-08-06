#!/bin/bash

set -e

source $PWD/ext/bash-tap/bash-tap
# plan tests 2

GIT_HUB_TEST_MODE="1"
GIT_HUB_CONFIG=$PWD/test/test-config

ok $a "lala"

done_testing
