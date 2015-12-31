#!/bin/bash

set -e

main() {
  assert-env "$@"
  make-command "$@"
  make-test-case-dir
  make-run-bash
  run-command
  clean-json
  clean-head

  echo "Created '$TEST_CASE_PATH'"
}

assert-env() {
  # TEST_DIR="$PWD/foo"
  TEST_DIR="$PWD/test/commands"

  TEST_BIN="$PWD/test/bin"
  TEST_LIB="$PWD/test/lib"

  export PATH=$TEST_BIN:$TEST_LIB:$PATH

  export GIT_HUB_TEST_MAKE=true
  export GIT_HUB_TEST_INTERACTIVE=true
  export GIT_HUB_TEST_COLS=80
  export GIT_HUB_TEST_LINES=24

  [[ -z $GIT_DIR ]] && die "GIT_DIR must be set"
  [[ $GIT_DIR =~ test/repo/[-_a-zA-Z0-9]+/?$ ]] ||
    die 'Invalid value for $GIT_DIR'
  [[ -d $GIT_DIR ]] ||
    die 'Invalid value for $GIT_DIR'
  GIT_DIR_DIR="${GIT_DIR%/}"
  GIT_DIR_DIR="${GIT_DIR_DIR/*\//}"
}

make-command() {
  [[ $# -ne 1 ]] && die "usage: GIT_DIR=... make-command-test 'git hub command'"
  TEST_CASE_CMD="$@"
}

make-test-case-dir() {
  test_dir="$TEST_DIR/${test_dir// /_}"
  TEST_CASE_DIR="${GIT_DIR_DIR}:${TEST_CASE_CMD// /_}"
  TEST_CASE_PATH="$TEST_DIR/$TEST_CASE_DIR"
  mkdir -p "$TEST_CASE_PATH"
}

make-run-bash() {
  cat <<... > $TEST_CASE_PATH/run.bash
export GIT_DIR=\$TEST_DIR/../repo/$GIT_DIR_DIR
$TEST_CASE_CMD
...
}

run-command() {
  export GIT_HUB_CACHE="$TEST_CASE_PATH"
  $TEST_CASE_CMD > "$TEST_CASE_PATH/stdout" 2> "$TEST_CASE_PATH/stderr"
}

clean-json() {
  for o in $TEST_CASE_PATH/*/out; do
    if [[ -s $o ]]; then
      $TEST_BIN/clean-json.rb $o
    fi
  done
}

clean-head() {
  for h in $TEST_CASE_PATH/*/head; do
    if [[ -s $h ]]; then
      $TEST_BIN/clean-head.rb $h
    fi
  done
}

die() { echo "$@" >&2; exit 1; }

main "$@"
