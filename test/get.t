#!/usr/bin/env bash

source test/setup

use Test::More tests 7
use JSON

tree1=$(cat test/test1.json | JSON.load)
ok $?                           "JSON.load succeeded"
is "$(JSON.get '/owner/login' tree1)" '"ingydotnet"' \
                                "JSON.get works"
is "$(JSON.get -s '/owner/login' tree1)" 'ingydotnet' \
                                "JSON.get -s works"
is $(JSON.get -s '/id' tree1 2> /dev/null || echo $?) 1 \
                                "JSON.get -s failure works"

JSON.load "$(< test/test1.json)"
ok $?                           "JSON.load succeeded"
is "$(JSON.get '/owner/login' -)" '"ingydotnet"' \
                                "JSON.get works"
is "$(cat test/test1.json | JSON.load | JSON.get -a "/owner/login")" \
  'ingydotnet' \
  'JSON.get works with piped data'

# XXX Disabling for now because we can't depend on pipefail
# Maybe use a tee and `wc -l` and check 0 or 1
# JSON.get '/bad-key' -
# ok [ $? -eq 1 ]                 "JSON.get on bad key fails"
