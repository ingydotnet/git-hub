#!/bin/bash
#
# git-hub: Use the GitHub v3 API commands from git
#
# Copyright (c) 2013 Ingy döt Net

set -e

OPTIONS_SPEC="\
git hub repos-list [<user-name>]
git hub repos-create <repo-name>
git hub repos-delete [<username>/]<repo-name>
git hub config [(api-token|user-name) [<new-value>]]
--
u,user=     GitHub user or organization
r,repo=     Name of repository
t,token=    GitHub v3 API Authentication Token

h,help      Show this help
q,quiet		Show minimal output
v,verbose   Show verbose output
d,dryrun    Don't run the API command
T,token     Show API token in the verbose output
x,			Turn on Bash trace output
"

main() {
	assert-env
	get-options "$@"
	github-"$command"
}

#------------------------------------------------------------------------------
github-repos-list() {
	local options='sort=pushed'
	local show=
	fetch-value user-name "$user"
	if [ -n "$user_name" ]; then
		show='name'
		api-get "users/$user_name/repos?$options"
	else
		show='full_name'
		api-get "user/repos?$options"
	fi
	[ -n "$dryrun" ] && return
	if OK; then
		echo "Repository list:"
		cat $GIT_HUB_OUTPUT |
			grep "\"$show\"" |
			perl -pe 's/^.*"(.*)",?$/- $1/'
	else
		die "Repository list failed."
	fi
}

github-repos-create() {
	require-value repo-name "$repo"
	local json=$(json-object \
		'name' $repo_name \
	)
	api-post 'user/repos' $json
	if OK; then
		say "Repository '$repo_name' created."
	else
		die "Repository creation failed."
	fi
}

github-repos-delete() {
	require-value repo-name "$repo"
	require-value user-name "$user"
	api-delete "repos/$user_name/$repo_name"
	if OK; then
		say "Repository '$user_name/$repo_name' deleted"
	else
		die "Repository deletion failed."
	fi
}

#------------------------------------------------------------------------------
github-config() {
	[ -n "$verbose" ] && echo "# From $config_file:"
	if [ -z "$config_key" ]; then
		cat $config_file
	elif [ -z "$config_value" ]; then
		[ -n "$verbose" ] && echo -n "  github.$config_key: "
		git config -f $config_file github.$config_key
	else
		[ -n "$verbose" ] && echo -n "  github.$config_key = $config_value"
		git config -f $config_file github.$config_key "$config_value"
	fi
}

#------------------------------------------------------------------------------
api-call() {
    OK=
	require-value api-token "$token"
	local action=$1
	local url=$2
	local data=$3
	[ -n "$data" ] && data="-d $data"
	if [ $verbose ]; then
		local token=$api_token
		[ -z "$show_token" ] && token='********'
		say curl -s -S -X$action -H "Authorization: token $token" $GIT_HUB_API_URI/$url $data
	fi
	if [ -n "$dryrun" ]; then
		OK=1
		return
	fi
	curl -s -S -X$action -H "Authorization: token $api_token" -D "$GIT_HUB_HEADER" $GIT_HUB_API_URI/$url $data > $GIT_HUB_OUTPUT 2> $GIT_HUB_ERROR
	[ $? -eq 0 ] && OK=1
	[ -n "$verbose" ] && cat $GIT_HUB_OUTPUT $GIT_HUB_ERROR
	true
}

api-get() { api-call GET $*; }
api-post() { api-call POST $*; }
api-put() { api-call PUT $*; }
api-delete() { api-call DELETE $*; }

OK() {
	if [ -n "$OK" ]; then
		return 0
	else
		return 1
	fi
}

#------------------------------------------------------------------------------
# Usage: require-value variable-name "possible-user-value"
#   Fetch $variable_name or die
require-value() {
	local key=$1
	local var=${key//-/_}
	fetch-value "$@"
	[ -n "$(eval echo \$$var)" ] && return
	die "Can't find value for '$var'"
}

# Usage: fetch-value variable-name "possible-user-value"
#   Sets $variable_name to the first of:
#   - possible-user-value
#   - $GIT_HUB_VARIABLE_NAME
#   - git config github.variable-name
fetch-value() {
	local key=$1
	local var=${key//-/_}
	local env=GIT_HUB_${var^^*}
	eval $var="$2"
	[ -n "$(eval echo \$$var)" ] && return
	eval $var=\"\$$env\"
	[ -n "$(eval echo \$$var)" ] && return
	eval $var=$(git config --file=$config_file github.$key || echo '')
	[ -n "$(eval echo \$$var)" ] && return
}

#------------------------------------------------------------------------------
# Format a JSON string from an input list of key/value pairs.
json-object() {
	local json='{'
	while [ $# -gt 0 ]; do
		json="$json\"$1\":\"$2\""
		shift; shift
		if [ $# -gt 0 ]; then
			json="$json,"
		fi
	done
	json="$json}"
	echo $json
}

#------------------------------------------------------------------------------
assert-env() {
	GIT_CORE_PATH=$(git --exec-path) || exit $?
	PATH=$GIT_CORE_PATH:$PATH

	GIT_HUB_API_URI=https://api.github.com
	GIT_HUB_TMP=/tmp
	GIT_HUB_TMP_PREFIX=$GIT_HUB_TMP/git-hub
	GIT_HUB_INPUT=$GIT_HUB_TMP_PREFIX-in-$$
	GIT_HUB_OUTPUT=$GIT_HUB_TMP_PREFIX-out-$$
	GIT_HUB_ERROR=$GIT_HUB_TMP_PREFIX-err-$$
	GIT_HUB_HEADER=$GIT_HUB_TMP_PREFIX-head-$$
	[ -z "$(which git)" ] &&
		echo "'git' command not found" && exit 1
	[ -z "$HOME" ] &&
		echo "Cannot determine HOME directory" && exit 1
	config_file=$GIT_HUB_CONFIG
	[ -n "$config_file" ] || config_file=$HOME/.githubconfig
	rm -f $GIT_HUB_TMP_PREFIX-*
}

get-options() {
	[ $# -eq 0 ] && set -- --help
	NONGIT_OK=1 source git-sh-setup
    # require_work_tree

	GIT_QUIET=; GIT_VERBOSE=;
	user=; repo=; verbose=; dryrun=; show_token=;
	while [ $# -gt 0 ]; do
		local option="$1"; shift
		case "$option" in
			-h) usage ;;
			-q) GIT_QUIET=1 ;;
			-u) user="$1"; shift ;;
			-r) repo="$1"; shift ;;
			-v) verbose="1"; ;;
			-d) echo '*** NOTE: This is a dryrun only. ***'
				dryrun="1" ;;
			-T) show_token="1" ;;
			-x) set -x ;;
			--) break ;;
			*) die "Unexpected option: $opt" ;;
		esac
	done
    command="$1"; shift
	case "$command" in
		repos-create|repos-delete)
			[ $# -gt 0 ] && repo="$1" && shift
			[ -n "$repo" ] || die "$command requires repo name"
			;;
		repos-list)
			[ $# -gt 0 ] && user="$1" && shift
			;;
		config)
			[ $# -gt 0 ] && config_key="$1" && shift
			[ $# -gt 0 ] && config_value="$1" && shift
			;;
		*) die "Unknown 'git hub' command: '$command'"
	esac
	[ $# -gt 0 ] && die "Unknown arguments: $*"
	true
}

#------------------------------------------------------------------------------
main "$@"

# vim: set tabstop=4 shiftwidth=4 noexpandtab:
