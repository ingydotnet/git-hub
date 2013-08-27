unset `env | cut -f1 -d= | grep '^GIT_HUB'`

export GIT_HUB_TEST_COMMAND=true

export GIT_HUB_USER_DIR=$PWD/test
export GIT_HUB_EXEC_PATH=$PWD/lib
export GIT_HUB_EXT_PATH=$GIT_HUB_EXEC_PATH/git-hub.d
export GIT_HUB_API_URI=https://api.github.com
export GIT_HUB_TMP_DIR="$test_dir"
export GIT_HUB_TMP_PREFIX=$GIT_HUB_TMP_DIR
export GIT_HUB_HEADER=$GIT_HUB_TMP_PREFIX/api-head
export GIT_HUB_OUTPUT=$GIT_HUB_TMP_PREFIX/api-out
export GIT_HUB_ERROR=$GIT_HUB_TMP_PREFIX/api-err
export GIT_HUB_CONFIG=$GIT_HUB_USER_DIR/githubconfig

export GIT_DIR=.no-git-repo
export GIT_EXEC_PATH=$GIT_HUB_EXEC_PATH
