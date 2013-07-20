#!/bin/bash

# This test is just a large grained, realtime test of the commands. Good to
# run before commit or release.

set -ex

## Reset section
if [ -n "$GIT_HUB_TEST_RESET" ]; then
    git hub repo-delete git-hub-api-test
    exit 0
fi

git hub user-info
git hub user cdent
git hub repo-info pegex-pm
git hub repo-list
git hub repos cdent
git hub repo cdent/simper
git hub repo-create git-hub-api-test
git hub repo-list
git hub repo-edit --repo=git-hub-api-test \
    description "This is just a test repo" \
    url http://example.com
git hub repo-info git-hub-api-test
git hub repo-delete git-hub-api-test
git hub collab-list
git hub repo-info

set +x

echo
echo All commands ran seemingly without error.

# vim: set ft=sh :
