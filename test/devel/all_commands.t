#!/bin/bash

# This test is just a large grained, realtime test of the commands. Good to
# run before commit or release.

set -e
source test/setup
use Test::More

ME="$(git hub config login)"
[ -n "$ME" ] || die "'git hub config login' has no value"

O1=git-commands
R1=git-hub-api-test
F1=$O1/$R1

U2=cdent
R2=simper
F2=$U2/$R2

deletes=("$F1" "$O1/$R2")
TEARDOWN() {
  rm -fr $R2
  for test_repo in "${deletes[@]}"; do
    ( set -x; git hub repo-delete $test_repo ) || true
  done
}

# Make sure test repos deleted (if left over from previous failure)
TEARDOWN

{
  set -x

  git hub -h || true
  git hub help user
  git hub user
  git hub user cdent
  git hub repo
  git hub repo pegex-pm
  git hub repos -c5
  git hub repos cdent --count=10
  git hub repo-new $F1
  git hub repo-edit $F1 \
    description "This is just a test repo" \
    homepage http://example.com
  git hub repo $F2
  git hub fork $F2 --org=$O1
  git hub clone $O1/$R2
  ok "`[ -d "$R2/.git" ]`" "$R2 repo directory exists"
  (
    cd $R2
    git hub repos
    git hub star
    git hub stars
    git hub repo
    git hub unstar
    git hub repo
  )
  git hub starred -c5
  git hub collabs

  set +x
}

TEARDOWN

pass 'All commands ran seemingly without error.'

done_testing

# vim: set ft=sh:
