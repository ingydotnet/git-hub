#!/usr/bin/env bash

source test/setup

use Test::More

{
  source lib/git-hub
  pass 'git-hub compiles'
}

{
  source lib/git-hub.d/git-hub-setup
  pass 'git-hub-setup compiles'
}

{
  source lib/git-hub.d/git-hub-setup
  pass 'git-hub-setup compiles'
}

{
  source lib/git-hub.d/git-hub-cache-clear
  pass 'git-hub-cache-clear compiles'
}

done_testing 4
