#!/bin/bash

set -e -o pipefail

export GIT_EXEC_PATH=$PWD/lib:$(git --exec-path)
git hub followers -qrc2 | git hub user - -j
