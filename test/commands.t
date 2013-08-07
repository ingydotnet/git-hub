#!/bin/bash

PATH=lib:ext/test-simple-bash/lib:ext/json-bash/lib:$PATH
source test-simple.bash tests 22

GIT_HUB_TEST_MODE="1"
GIT_HUB_TEST_COMMAND="1"
GIT_HUB_CONFIG=$PWD/test/githubconfig

source $PWD/lib/git-hub
GitHub.assert-env

foo_git=./test/foo.git
fake_token=0123456789ABCDEF

test_command() {
    local TestSimple_CALL_STACK_LEVEL=2
    died=false
    die_msg=
    [ -n "$D" ] && diag "$expected"
    if [ -n "$2" ]; then
        GIT_DIR="$2"
    else
        GIT_DIR=not-in-git-dir
    fi
    eval set -- "$1"
    GitHub.get-options "$@"
    # subvert git-core/git-sh-setup's die
    die_with_status () {
        shift
        die_msg="$@"
        died=true
    }
    "GitHub.$command"
    local curl="${curl_command[@]}"
    local label="$1"
    label=$(printf "%-40s %s" "$label" "($GIT_DIR)")
    if [ "$expected" = DIE ]; then
        died_properly=$(
            $died && [[ $die_msg =~ $expect_die_message ]] &&
            echo true || echo false
        )
        ok $died_properly "$1; dies with '$expect_die_message'" || {
            if $died; then
                diag "Want: $expect_die_message"
                diag "Got:  $die_msg"
            else
                diag "Did't die. Got: $curl"
            fi
        }
    else
        ok [ -z "$die_msg" -a "$curl" = "$expected" ] "$label" || {
            if $died; then
                diag "Died: $die_msg"
            else
                diag "Want: $expected"
                diag "Got:  $curl"
            fi
        }
        true
    fi
    [ -n "$D" ] && exit 1
    true
}

expect() {
    local action="$1"; shift
    if [[ $action = DIE ]]; then
        expected=$action
        expect_die_message="$@"
    else
        suffix=${@/AUTH/--header Authorization: token $fake_token}
        expected="curl --request $action https://api.github.com$suffix"
    fi
}

note() {
    echo "# $@"
}

diag() {
    echo "# $@" >&2
}
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

expect DIE Unknown argument: ricardo
test_command 'orgs tommy ricardo'

#----------------------------------------------------------------------------
note "Test 'org' commands:"

expect GET /orgs/acmeism
test_command 'org acmeism'

expect DIE "Can't find value for 'org_name'"
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

#----------------------------------------------------------------------------
note "Test 'forks' commands:"

#----------------------------------------------------------------------------
note "Test 'fork' commands:"

#----------------------------------------------------------------------------
note "Test 'stars' commands:"

#----------------------------------------------------------------------------
note "Test 'star' commands:"

#----------------------------------------------------------------------------
note "Test 'unstar' commands:"

#----------------------------------------------------------------------------
note "Test 'starred' commands:"

#----------------------------------------------------------------------------
note "Test 'collabs' commands:"

#----------------------------------------------------------------------------
note "Test 'trust' commands:"

#----------------------------------------------------------------------------
note "Test 'untrust' commands:"

#----------------------------------------------------------------------------
note "Test 'followers' commands:"

#----------------------------------------------------------------------------
note "Test 'following' commands:"

#----------------------------------------------------------------------------
note "Test 'follow' commands:"

#----------------------------------------------------------------------------
note "Test 'unfollow' commands:"

