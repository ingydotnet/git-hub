#!/usr/bin/env bash

source test/setup
use Test::More

plan tests 2

ok "`source git-hub-travis-enable`" 'git-hub-travis-enable loads'
ok "`source git-hub-travis-disable`" 'git-hub-travis-disable loads'

# vim: set ft=sh:
