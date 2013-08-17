#!/bin/bash

set -o pipefail
users=$(echo cdent; echo mml)
git hub followers -qrc2 | git hub user - -j
