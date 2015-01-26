#!/usr/bin/env bash

source test/setup

use Test::More tests 2
use JSON

tree1=$(cat test/test1.json | JSON.load)
ok $?                           "JSON.load succeeded"

is "$(JSON.get '/id' tree1)" '12345678' \
                                "JSON.get works on first element"
