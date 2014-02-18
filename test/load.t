#!/usr/bin/env bash

source test/setup

use Test::More tests 13
use JSON

tree1=$(cat test/test1.json | JSON.load)
ok $?                 "JSON.load succeeded"
[ -z "$JSON__cache" ]
ok $?                 "JSON__cache is unset"
[ -n "$tree1" ]
ok $?                 "load result has content"

echo "$tree1" | grep -E "^/owner/login" &> /dev/null
ok $?  "load output contains login key"

is $(echo "$tree1" | wc -l) 12 \
                      "linear tree has 12 values"

JSON.load "$(cat test/test1.json)"
ok $?                 "JSON.load succeeded"
[ -n "$JSON__cache" ]
ok $?                 "JSON__cache is set"

JSON.cache | grep -E '^/description' &> /dev/null
ok $?                 "load output contains description"

is $(JSON.cache | wc -l) 12 \
                      "linear tree has 12 values"

JSON.load "$(cat test/test1.json)" tree2
ok $?                 "JSON.load succeeded"
[ -z "$JSON__cache" ]
ok $?                 "JSON__cache is set"

echo "$tree2" | grep -E '^/id' &> /dev/null
ok $?  "load output contains id"

is $(echo -n "$tree2" | wc -l) 12 \
                      "linear tree has 12 values"

