#!/bin/bash

cmd_bin=$PWD/git-hub
tmp=./tmp
config=$HOME/.githubconfig

die() {
    echo "$*"
    exit 1
}

# Assert sanity
if [ -z "$(which git)" ]; then
    die "'git' doesn't seem to be installed"
fi
if [ ! -f $cmd_bin ]; then
    die "Can't test 'git-hub': '$cmd_bin' file not found"
fi
if [ ! -x $cmd_bin ]; then
    die "'$cmd_bin' is not executable"
fi
if [ ! -f $config ]; then
    die "'git-hub' is not configured. Can't find '$config'."
fi

PATH=$PWD:$PATH
rm -fr $tmp

if [ -z $(git hub config api-token) ]; then
    cat <<_
Error:
    '$config' has no 'api-token' key.

Try:
  git hub config api-token <your-oauth2-token>

Get your token here: https://github.com/settings/applications
_
    exit 1
fi
