#!/usr/bin/env bash

source test/setup

use Test::More tests 5
use JSON

tree1=$(cat test/keys.json | JSON.load)
ok $? \
    "JSON.load succeeded"

is "$(JSON.get '/files/file 2.txt/type' tree1)" \
    '"text/plain"' \
    "JSON.get works"

file_object=$(JSON.object '/files' tree1)

keys="$(JSON.keys '/' file_object)"
is "$keys" \
    "file1.txt"$'\n'"file 2.txt" \
    "JSON.keys '/'" #'

keys="$(JSON.keys '/files' tree1)"
is "$keys" \
    "file1.txt"$'\n'"file 2.txt" \
    "JSON.keys '/files'" #'

keys="$(JSON.keys '/' tree1)"
is "$keys" "description"$'\n'"files" \
    "JSON.keys '/'" #'
