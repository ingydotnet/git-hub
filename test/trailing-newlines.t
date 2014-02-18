#!/usr/bin/env bash

source test/setup

use Test::More tests 4
use JSON

trailing_newline_re=$'\n''$'
json_string='{"foo": "bar", "baz": "quux"}'

JSON.load "$json_string"
[[ "$JSON__cache" =~ $trailing_newline_re ]]
ok $? "JSON__cache has trailing newline" || echo -n "$JSON__cache" | hexdump -C

JSON.load "$json_string" tree
[[ "$tree" =~ $trailing_newline_re ]]
ok $? "linear tree has trailing newline" || echo -n "$tree" | hexdump -C

JSON.load "{}"
[[ "$JSON__cache" == '' ]]
ok $? "empty JSON__cache has no trailing newline" || echo -n "$JSON__cache" | hexdump -C

JSON.load "[]" tree
[[ "$tree" == '' ]]
ok $? "empty linear tree has no trailing newline" || echo -n "$tree" | hexdump -C
