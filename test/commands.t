#!/usr/bin/env bash

source test/setup

use Test::More

if [[ -n $ALL_TESTS ]]; then
  ALL_TESTS=($ALL_TESTS)
else
  ALL_TESTS=()
  for dir in $TEST_DIR/*/run.bash; do
    dir="$(dirname "$dir")"
    if [[ ! -e $dir/skip:${OSTYPE/[0-9]*/} ]]; then
      ALL_TESTS+=("$dir")
    fi
  done
fi

main() {
  export PATH=$TEST_LIB:$PATH
  for test_dir in "${ALL_TESTS[@]}"; do


    # XXX Bug in _repos commands since internal pager removed
    [[ $test_dir =~ _repos ]] && continue


    export GIT_HUB_CACHE="$test_dir"
    bash $test_dir/run.bash \
      > "$TEST_DIR/stdout" \
      2> "$TEST_DIR/stderr" || true
    file-test stdout
    file-test stderr
    rm -f "$TEST_DIR/stdout"
    rm -f "$TEST_DIR/stderr"
  done
  done_testing
}

file-test() {
  local file="$1"
  local label=$test_dir
  label="${label#$TEST_DIR/}"
  label+=" ($file)"
  is "$(< "$TEST_DIR/$file")" "$(< "$test_dir/$file")" "$label"
}

main "$@"

# vim: set ft=sh:
