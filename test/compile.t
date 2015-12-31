#!/usr/bin/env bash

source test/setup

use Test::More

{
  source lib/git-hub
  pass 'git-hub compiles'
}

for f in lib/git-hub lib/git-hub.d/*; do
  [[ -f $f ]] || continue
  if [[ $f =~ \.pl$ ]]; then
    perl -c $f &>/dev/null
  else
    source "$f"
  fi
  pass "${f##*/} compiles"
done

done_testing
