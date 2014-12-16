#!/usr/bin/env bash

source test/setup

use Test::More

# use git-hub
source git-hub

rm -fr tmp
mkdir tmp

url="$(
  cd tmp
  (
    git init
    git remote add origin git@github.com:test/test
    touch foo
    git add foo
    git commit -m ...
    git checkout -b bar
  ) 2>&1 > /dev/null
  git hub url
)"
like "$url" bar "'git hub url' repects branches"

rm -fr tmp

done_testing
