#!/bin/bash
#
# git-hub: Use the GitHub v3 API commands from git
#
# Copyright (c) 2013 Ingy döt Net

set -e

OPTIONS_SPEC="\
git hub <command> <options> <arguments>

Commands:
  auth-list, auth-info, auth-create, auth-update, auth-delete
  repo-list, repo-info, repo-create, repo-delete
  user-info, user-update
  collab-add, collab-remove
  config

See 'git help hub' for complete documentation and usage of each command.

Options:
--
user=       GitHub user name
owner=      GitHub user who owns a repository
org=        GitHub organization name
repo=       GitHub repository name
token=      GitHub v3 API Authentication Token
c,count=    Number of items to process

h,help      Show this help
q,quiet     Show minimal output
v,verbose   Show verbose output
d,dryrun    Don't run the API command
T,token     Show API token in the verbose output

x           dev - Turn on Bash trace output
R           dev - Repeat last command without contacting server
"

main() {
	assert-env
	get-options "$@"
	setup-env

	github-"$command"

	if OK; then
		if callable "github-$command-success"; then
			"github-$command-success"
		else
			say ${message_success:="'git hub $command' successful"}
		fi
	elif callable "github-$command-$status_code"; then
		"github-$command-$status_code"
	elif [ -n "$(eval "echo \$message_$status_code")" ]; then
		say $(eval "echo \$message_$status_code")
	elif callable "github-$command-failure"; then
		"github-$command-failure"
	else
		say ${message_failure:="'git hub $command' failed: $status_code $ERROR"}
	fi
}

#------------------------------------------------------------------------------
github-auth-list() {
	api-get 'authorizations'
	cat $GIT_HUB_OUTPUT
}

github-repos-list() {
	local options='sort=pushed'
	if [ -n "$user_name" ]; then
		api-get "users/$user_name/repos?$options"
	else
		api-get "user/repos?$options"
	fi
}

github-repos-list-success() {
	echo "Repository list:"
	regex_name='"name": +"(.*)"'
	regex_pushed_at='"pushed_at": +"(.*)"'
	while read line; do
		[[ $line =~ $regex_name ]] &&
			echo "- name: ${BASH_REMATCH[1]}"
		[[ $line =~ $regex_pushed_at ]] &&
			echo "  pushed_at: ${BASH_REMATCH[1]}"
	done < $GIT_HUB_OUTPUT
}

github-repos-create() {
	require-value repo-name "$repo"
	local json=$(json-object \
		'name' $repo_name \
	)
	api-post 'user/repos' $json
	message_success="Repository '$repo_name' created."
	message_422="Repository name '$repo_name' already exists."
}

github-repos-delete() {
	require-value repo-name "$repo"
	require-value user-name "$user"
	api-delete "repos/$user_name/$repo_name"
	message_success="Repository '$repo_name' deleted"
}

github-user-info() {
	require-value user-name "$user"
	api-get "users/$user_name"
}

github-user-info-success() {
	cat $GIT_HUB_OUTPUT
}

github-collab-add() {
	require-value repo-name "$repo"
	require-value user-name "$user"
	require-value collab-name "$collab"
	api-put "repos/$user_name/$repo_name/collabs/$collab_name"
	message_success="Added '$collab_name' as a collaborator to the '$repo_name' repository"
}

#------------------------------------------------------------------------------
github-config() {
	if [ -z "$config_key" ]; then
		cat $config_file
	elif [ -z "$config_value" ]; then
		git config -f $config_file github.$config_key
	else
		git config -f $config_file github.$config_key "$config_value"
	fi
}

#------------------------------------------------------------------------------
api-get() { api-call GET $*; }
api-post() { api-call POST $*; }
api-put() { api-call PUT $*; }
api-delete() { api-call DELETE $*; }

api-call() {
	[ -n "$GIT_HUB_REPEAT_COMMAND" ] && api-repeat && return
	require-value api-token "$token"
	local action=$1
	local url=$2
	local data=$3
	[ -n "$data" ] && data="-d $data"
	if [ $GIT_VERBOSE ]; then
		local token=$([ -n "$show_token" ] && echo "$api_token" || echo '********')
		say "curl -s -S -X$action -H \"Authorization: token $token\" $GIT_HUB_API_URI/$url $data -D \"$GIT_HUB_HEADER\" > $GIT_HUB_OUTPUT 2> $GIT_HUB_ERROR"
	fi
	[ -n "$dryrun" ] && exit 0
	curl -s -S -X$action -H "Authorization: token $api_token" \
		$GIT_HUB_API_URI/$url $data \
		-D "$GIT_HUB_HEADER" > $GIT_HUB_OUTPUT 2> $GIT_HUB_ERROR
	check-api-call-status $?
}

check-api-call-status() {
	OK=$1
	if [ ! -f $GIT_HUB_HEADER ]; then
		OK=1
		ERROR=$(head -1 $GIT_HUB_ERROR)
		return
	fi
	status_code=$(head -1 $GIT_HUB_HEADER | cut -d ' ' -f2)
	local regex='^[0-9]{3}$'
	[[ $status_code =~ $regex ]] || return
	case "$status_code" in
		200|201|204) OK=0 ;;
		*)
			OK=1
			ERROR=$(head -1 $GIT_HUB_HEADER | cut -d ' ' -f3-)
			;;
	esac
}

OK() {
	return $OK
}

api-repeat() {
	check-api-call-status 0
	true
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
	local env=GIT_HUB_$(echo $var | tr 'a-z' 'A-Z')
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

	: ${GIT_HUB_API_URI:=https://api.github.com}
	GIT_HUB_TMP=/tmp
	GIT_HUB_TMP_PREFIX=$GIT_HUB_TMP/git-hub
	GIT_HUB_INPUT=$GIT_HUB_TMP_PREFIX-in-$$
	GIT_HUB_OUTPUT=$GIT_HUB_TMP_PREFIX-out-$$
	GIT_HUB_ERROR=$GIT_HUB_TMP_PREFIX-err-$$
	GIT_HUB_HEADER=$GIT_HUB_TMP_PREFIX-head-$$
	local cmd
	for cmd in git curl; do
		[ -z "$(which $cmd)" ] &&
			echo "Required command not found: '$cmd'" && exit 1
	done
	[ -z "$HOME" ] &&
		echo "Cannot determine HOME directory" && exit 1
	config_file=$GIT_HUB_CONFIG
	[ -n "$config_file" ] || config_file=$HOME/.githubconfig
}

get-options() {
	[ $# -eq 0 ] && set -- --help
	NONGIT_OK=1 source git-sh-setup

	GIT_QUIET=; GIT_VERBOSE=;
	user=; repo=; dryrun=; show_token=;
	while [ $# -gt 0 ]; do
		local option="$1"; shift
		case "$option" in
			-h) usage ;;
			-u) user="$1"; shift ;;
			-r) repo="$1"; shift ;;
			-t) token="$1"; shift ;;
			-d) dryrun="1" ;;
			-T) show_token="1" ;;
			-q) GIT_QUIET=1 ;;
			-v) GIT_VERBOSE="1"; ;;
			-x) set -x ;;
			--) break ;;
			*) die "Unexpected option: $option" ;;
		esac
	done
    command="$1"; shift
	case "$command" in
		auth-list) ;;
		repo-create|repo-delete)
			[ $# -gt 0 ] && repo="$1" && shift
			;;
		repo-list)
			[ $# -gt 0 ] && user="$1" && shift
			;;
		user-info)
			[ $# -gt 0 ] && user="$1" && shift
			;;
		config)
			[ $# -gt 0 ] && config_key="$1" && shift
			[ $# -gt 0 ] && config_value="$1" && shift
			;;
		collab-add)
			[ $# -gt 0 ] && repo="$1" && shift
			[ $# -gt 0 ] && collab="$1" && shift
			;;
		*) die "Unknown 'git hub' command: '$command'"
	esac
	[ $# -gt 0 ] && die "Unknown arguments: $*"
	true
}

setup-env() {
    if [ -n "$GIT_HUB_REPEAT_COMMAND" ]; then
		[ -f $GIT_HUB_TMP_PREFIX-out-* ] ||
			die "No previous 'git hub' command to repeat"
		local old_output=$(echo $GIT_HUB_TMP_PREFIX-out-*)
		local pid=${old_output/$GIT_HUB_TMP_PREFIX-out-/}
		GIT_HUB_INPUT=$GIT_HUB_TMP_PREFIX-in-$pid
		GIT_HUB_OUTPUT=$GIT_HUB_TMP_PREFIX-out-$pid
		GIT_HUB_ERROR=$GIT_HUB_TMP_PREFIX-err-$pid
		GIT_HUB_HEADER=$GIT_HUB_TMP_PREFIX-head-$pid
	else
		rm -f $GIT_HUB_TMP_PREFIX-*
	fi
	[ -n "$dryrun" ] &&
		say '*** NOTE: This is a dryrun only. ***'
	true
    # require_work_tree
}

#------------------------------------------------------------------------------
callable() {
	[ -n "$(type $1 2> /dev/null)" ]
}

#------------------------------------------------------------------------------
main "$@"

# vim: set tabstop=4 shiftwidth=4 noexpandtab:
