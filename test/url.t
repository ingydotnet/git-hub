#!/usr/bin/env bash

# Set up the test environment (PATH, etc)
source test/setup
# This is set for other tests, but cause problems here
unset GIT_DIR

# Pull in TAP framework (from ext/test-more-bash)
use Test::More

# Make a test repo dir called tmp
# TODO: this should be abstracted
rm -fr tmp
mkdir tmp

# Create a basic repo with a 'bar' branch
# Run our test command and capture the output
# Parens () create a subprocess
url="$(
  # This will change back to current dir after we exit subprocess
  cd tmp
  # Set up dir as a minimal repo the way we want it.
  # D it in subprocess and throw away output
  (
    git init
    git remote add origin git@github.com:test/test
    touch foo
    git add foo
    git commit -m ...
    git checkout -b bar
  ) &> /dev/null
  # Run the test command
  git hub url
)"
# Make sure output URL has 'bar' in it:
like "$url" bar "'git hub url' repects branches"

# Clean up test repo:
rm -fr tmp

done_testing
