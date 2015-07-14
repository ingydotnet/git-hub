#!/usr/bin/env bash

source test/setup

use Test::More
use JSON

tree1=$(cat test/issue4.json | JSON.load)
ok $? "JSON.load succeeded"

done_testing
