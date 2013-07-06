#!/bin/bash

rm -fr tmp
mkdir -p tmp/test-git-hub-repo1
(
    cd tmp/test-git-hub-repo1
    echo 'Test git-hub repo #1' > README
    git init -q
    git add README
    git commit -q -m 'First commit'
    git hub repos-create --repo=goop
    git hub repos-delete --repo=goop
)
