#!/bin/bash

set -e

die() { echo "$@" >&2; exit 1; }

export TEST_DIR="$PWD/test/commands"
export TEST_BIN="$PWD/test/bin"
export TEST_LIB="$PWD/test/lib"
if [ -n "$ALL_TESTS" ]; then
    ALL_TESTS=($ALL_TESTS)
else
    ALL_TESTS=()
    for dir in $TEST_DIR/*/run.bash; do
        dir="$(dirname "$dir")"
        if [ ! -e "$dir/skip:${OSTYPE/[0-9]*/}" ]; then
            ALL_TESTS+=("$dir")
        fi
    done
fi

PATH=ext/test-simple-bash/lib:$PATH \
source test-simple.bash tests $(( ${#ALL_TESTS[@]} * 2 ))
TestSimple_CALL_STACK_LEVEL=2

main() {
    export PATH=$TEST_LIB:$PATH
    for test_dir in "${ALL_TESTS[@]}"; do
        source setup.bash
        bash $test_dir/run.bash \
          > "$TEST_DIR/stdout" \
          2> "$TEST_DIR/stderr" || true
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
