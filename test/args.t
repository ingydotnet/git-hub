#!/bin/bash

set -e

PATH=ext/test-simple-bash/lib:$PATH
source test-simple.bash tests 10
note() {
    echo "# $@"
}
diag() {
    echo "# $@" >&2
}

PATH=lib:$PATH
source git-hub

run-test() {
    local spec="$1"
    local expect="$2"
    local a=("$@")
    local opts=('<cmd>' "${a[@]:2}")
    local label="git hub ${opts[@]}"
    get-opts "${opts[@]}"
    get-args $spec
    local got="$(result $spec)"
    ok [ "$got" == "$expect" ] "$label" || {
        diag "Want: $expect"
        diag "Got:  $got"
    }
}
result() {
    local spec="$@"
    spec="${spec#\?}"
    spec="${spec/\// }"
    IFS=' ' read -a specs <<< "$spec"
    local format='='
    for s in "${specs[@]}"; do
        s=${s/:*/}
        format+="\$$s="
    done
    eval echo $format
}
run-test-error() {
    local a=("$@")
    local expect="$1"
    set -- "$2" "XXX" "${a[@]:2}"
    local opts=('<cmd>' "${a[@]:2}")
    local label="ERROR: git hub ${opts[@]}"
    local error=$(run-test "$@" 2>&1)
    local ok
    [[ "$error" =~ "$expect" ]] && ok=true || ok=false
    ok $ok "$label" || {
        diag "Pattern: $expect"
        diag "Not in:  $error"
    }
}

export GIT_DIR=$PWD/test/not-a-repo
GIT_HUB_CONFIG=$PWD/test/githubconfig
RICARDO_FOO=$PWD/test/ricardo-foo

run-test \
    "?user_name:get-user" \
    "=billy=" \
    billy

run-test \
    "?user_name:get-user" \
    "=tommy=" \
    # none

GIT_DIR=$RICARDO_FOO run-test \
    "?user_name:get-user" \
    "=ricardo=" \
    # none

run-test-error \
    "Can't find a value for 'user_name'" \
    "?user_name:get-owner" \
    # none

run-test-error \
    "Unknown arguments 'xxx yyy'" \
    "?user_name:get-login" \
    fred xxx yyy

run-test \
    "user_name:get-login" \
    "=billy=" \
    billy

run-test-error \
    "Can't find a value for 'user_name'" \
    "user_name:get-owner" \
    # none

run-test \
    "?user:get-user/repo:get-repo key" \
    "=jimmy=juju=type=" \
    jimmy/juju type

GIT_DIR=$RICARDO_FOO run-test \
    "?user:get-user/repo:get-repo key" \
    "=ricardo=foo=type=" \
    type

run-test-error \
    "Invalid value 'jimmy' for 'user/repo'" \
    "user/repo key" \
    jimmy type
