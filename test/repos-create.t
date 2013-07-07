#!/bin/bash

source test/setup.sh

repo_name=TEST-git-hub-repos-create

git hub repos-create --repo=$repo_name
git hub repos-delete --repo=$repo_name
