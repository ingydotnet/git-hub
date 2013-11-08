#!/bin/bash

set -e

source test/setup

use Test::More

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
    done_testing
}

file-test() {
    local file="$1"
    local label=$test_dir
    label="${label#$TEST_DIR/}"
    label+=" ($file)"
    is "$(< "$test_dir/$file")" "$(< "$TEST_DIR/$file")" "$label"
}

main "$@"
