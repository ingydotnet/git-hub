#!/usr/bin/env bash

set -e

source test/setup

use Test::More

# use git-hub
source git-hub

files=("$(find lib/git-hub.d plugin/*/lib -type f | sort)")

for file in ${files[@]}; do
  library=${file##*/}
  if [[ "$library" =~ ^git-hub ]] || [[ "$library" =~ \.bash$ ]]; then
    (source "$file" &> /dev/null) && OK=$? || OK=$?
    ok $OK "'source $file' works"
  elif [[ "$library" =~ \.pl$ ]]; then
    (perl -c "$file" &> /dev/null) && OK=$? || OK=$?
    ok $OK "'perl -c $file' works"
  fi
done

done_testing

# vim: set ft=sh:
