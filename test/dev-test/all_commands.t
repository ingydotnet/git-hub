#!/bin/bash

# This test is just a large grained, realtime test of the commands. Good to
# run before commit or release.

set -ex

## Reset section
if [ -n "$GIT_HUB_TEST_RESET" ]; then
    git hub repo-delete git-hub-api-test
    exit 0
fi

git hub user
git hub user cdent
git hub repo pegex-pm
git hub repos
git hub repos cdent
git hub repo cdent/simper
git hub create git-hub-api-test
git hub repos
git hub repo-edit ingydotnet/git-hub-api-test \
    description "This is just a test repo" \
    homepage http://example.com
git hub repo git-hub-api-test
git hub repo-delete git-hub-api-test
git hub collabs
git hub repo

set +x

echo
echo All commands ran seemingly without error.

# vim: set ft=sh :
