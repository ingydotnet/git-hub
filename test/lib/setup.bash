unset `env | cut -f1 -d= | grep '^GIT_HUB' | grep -v 'GIT_HUB_JSON_LIB'`

export GIT_HUB_TEST_RUN=true

export GIT_HUB_USER_DIR=$PWD/test
export GIT_HUB_EXEC_PATH=$PWD/lib
export GIT_HUB_EXT_PATH=$GIT_HUB_EXEC_PATH/git-hub.d
export GIT_HUB_API_URI=https://api.github.com
export GIT_HUB_CACHE="$test_dir"
export GIT_HUB_CONFIG=$GIT_HUB_USER_DIR/githubconfig

export GIT_DIR=.no-git-repo
export GIT_EXEC_PATH=$GIT_HUB_EXEC_PATH
