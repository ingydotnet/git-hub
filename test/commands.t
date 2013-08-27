#!/bin/bash

die() { echo "$@"; exit 1; }
set -e

ostype=${OSTYPE/[0-9]*/}
TEST_DIR="$PWD/test/commands"
if [ -z "$ALL_TESTS" ]; then
    ALL_TESTS=()
    for dir in $TEST_DIR/*/run.bash; do
        dir="$(dirname "$dir")"
        [ ! -e "$dir/skip:${OSTYPE/[0-9]*/}" ] &&
            ALL_TESTS+=("$dir")
        :
    done
fi

PATH=ext/test-simple-bash/lib:$PATH
source test-simple.bash tests $(( ${#ALL_TESTS[@]} * 2 ))
TestSimple_CALL_STACK_LEVEL=2
main() {
    export PATH=$TEST_DIR:$PATH
    for test_dir in "${ALL_TESTS[@]}"; do
        source setup.bash
        bash $test_dir/run.bash > "$TEST_DIR/stdout" 2> "$TEST_DIR/stderr"
        file-test stdout
        file-test stderr
        source teardown.bash
    done
}

file-test() {
    local file="$1"
    local label=$test_dir
    label="${label#$TEST_DIR/}"
    label+=" ($file)"
    local diff=$(diff -u "$test_dir/$file" "$TEST_DIR/$file")
    local result
    [ -z "$diff" ] && result=true || result=false
    ok $result "$label" || true
    [ -n "$diff" ] && diag "$diff"
    true
}

# XXX move to test-more.bash
note() { echo "# $@"; }
diag() { echo "# $@" >&2; }

main "$@"

: <<...
#----------------------------------------------------------------------------
note "Test all the permutations of command and arguments and environments"

note "Test 'user' commands:"

expect GET /users/tommy
test_command "user"

expect GET /users/geraldo
test_command "user geraldo"

expect GET /users/ricardo
test_command "user" $foo_git

expect GET /users/geraldo
test_command "user geraldo" $foo_git

#----------------------------------------------------------------------------
note "Test 'user-edit' commands:"

expect DIE Odd number of items
test_command 'user-edit tommy'

expect DIE Odd number of items
test_command 'user-edit tommy name tom'

expect PATCH /user -d '{"name":"Tomster"}' AUTH
test_command 'user-edit name Tomster'

expect PATCH /user -d '{"name":"Tomster"}' AUTH
test_command 'user-edit name Tomster' $foo_git

#----------------------------------------------------------------------------
note "Test 'orgs' commands:"

expect GET /users/tommy/orgs
test_command 'orgs'

expect GET /users/geraldo/orgs
test_command 'orgs geraldo'

expect GET /users/ricardo/orgs
test_command 'orgs' $foo_git

expect GET /users/geraldo/orgs
test_command 'orgs geraldo' $foo_git

expect DIE "Unknown argument\(s\): 'ricardo'"
test_command 'orgs tommy ricardo'

#----------------------------------------------------------------------------
note "Test 'org' commands:"

expect GET /orgs/acmeism
test_command 'org acmeism'

expect DIE "Can't find value for 'org'"
test_command 'org'

expect DIE Unknown argument: perl6
test_command 'org acmeism perl6'

#----------------------------------------------------------------------------
note "Test 'org-edit' commands:"

expect DIE key/value pairs, but none given
test_command 'org-edit godspeed'

expect DIE Odd number of items
test_command 'org-edit godspeed "Peedy Gods"'

expect PATCH /orgs/godspeed -d '{"name":"Peedy Gods"}' AUTH
test_command 'org-edit godspeed name "Peedy Gods"'

#----------------------------------------------------------------------------
note "Test 'members' commands:"

#----------------------------------------------------------------------------
note "Test 'teams' commands:"

#----------------------------------------------------------------------------
note "Test 'repos' commands:"

#----------------------------------------------------------------------------
note "Test 'repo' commands:"

expect 'GET' "/repos/tommy/xyz"
test_command "repo xyz"

expect 'GET' "/repos/ricardo/foo"
test_command "repo" $foo_git

expect 'GET' "/repos/geraldo/rivets"
test_command "repo geraldo/rivets"

expect 'GET' "/repos/ricardo/foo"
test_command "repo" $foo_noext

expect 'GET' "/repos/ricardo/foo"
test_command "repo" $foo_noorigin
...
