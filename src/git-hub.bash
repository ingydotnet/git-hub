#!/bin/bash
#
# git-hub: Use the GitHub v3 API commands from git
#
# Copyright (c) 2013 Ingy döt Net

set -e

OPTIONS_SPEC="\
git hub <command> <options> <arguments>

Commands:
  config
  user-info, user-update
  repo-list, repo-info, repo-create, repo-edit, repo-delete
  collab-list, collab-add, collab-remove

Aliases:
  user == user-info
  repos == repo-list
  repo == repo-info

See 'git help hub' for complete documentation and usage of each command.

Options:
--
user=       GitHub user name
repo=       GitHub repository name
token=      GitHub v3 API Authentication Token
c,count=    Number of items to process

h,help      Show this help
q,quiet     Show minimal output
v,verbose   Show verbose output
d,dryrun    Don't run the API command
T           Show API token in the verbose output
 
O           dev - Show response output
H           dev - Show reponse headers
J           dev - Show parsed JSON response
x           dev - Turn on Bash trace (set -x) output
R           dev - Repeat last command without contacting server
"

#------------------------------------------------------------------------------
main() {
	assert-env
	get-options "$@"
	setup-env

	! callable github-"$command" &&
		die "Unknown 'git hub' command: '$command'"
	github-"$command" "$@"
	[ -n "$show_headers" ] && cat $GIT_HUB_HEADER
	[ -n "$show_output" ] && cat $GIT_HUB_OUTPUT
	[ -s $GIT_HUB_OUTPUT ] && json-load-cache "$(< $GIT_HUB_OUTPUT)"
	[ -n "$show_json" ] && echo "$json_load_data_cache"

	if OK; then
		if callable "success-github-$command"; then
			"success-github-$command"
		else
			say ${message_success:-"'git hub $command' successful"}
		fi
		exit 0
	elif [ -n "$status_code" ] && callable "status-$status_code-github-$command"; then
		"status-$status_code-github-$command"
		exit 1
	elif [ -n "$(eval "echo \$message_$status_code")" ]; then
		say $(eval "echo \$message_$status_code")
		exit 1
	elif callable "failure-github-$command"; then
		"failure-github-$command"
		exit 1
	else
		say ${message_failure:="'git hub $command' failed: $status_code $ERROR"}
		exit 1
	fi
}

#------------------------------------------------------------------------------
# `git hub` command functions:
#------------------------------------------------------------------------------
github-config() {
    get-args config_key config_value
	if [ -z "$config_key" ]; then
		cat $config_file
	elif [ -z "$config_value" ]; then
		message_success=$(git config -f $config_file github.$config_key)
	else
		git config -f $config_file github.$config_key "$config_value"
		message_success="$config_key=$config_value"
	fi
	OK=$?
}

github-user-info() {
    get-args user
	require-value user-name "$user"
	api-get "/users/$user_name"
}

success-github-user-info() {
	for field in \
		login type name email blog location company \
		followers following public_repos public_gists
	do
		report-value $field
	done
}

github-user-update() {
	get-args *key_value_pairs
	api-patch "/user" "$(json-dump-object-pairs)"
}

github-repo-list() {
    get-args user
	require-value user-name "$user"
	page_size=100
	per_page=$list_count
	[ $per_page -gt $page_size ] && per_page=$page_size
	api-get "/users/$user_name/repos?sort=pushed;per_page=$per_page"
	counter=1
}

success-github-repo-list() {
	for ((ii=0; ii < $page_size; ii++)); do
		[ $counter -le $list_count ] || return 0
		name=$(json-get "/$ii/full_name")
		pushed=$(json-get "/$ii/pushed_at")
		pushed=${pushed/T*/}
		desc=$(json-get "/$ii/description")
		[ -z "$name" ] && break
		printf "%3d) (%s)  %-30s %s\n" $((counter++)) $pushed $name "$desc"
	done
	if [ $ii -ge $page_size ]; then
		get-next-page success-github-repo-list
	fi
}

github-repo-info() {
	get-args repo
	check-user-repo "$repo"
	require-value repo-name "$repo"
	require-value user-name "$user"
	api-get "/repos/$user_name/$repo_name"
}

success-github-repo-info() {
	for field in \
		full_name description homepage language \
		pushed_at \
		url ssh_url \
		forks watchers
	do
		report-value $field
	done
}

github-repo-create() {
	get-args repo
	require-value repo-name "$repo"
	api-post "/user/repos" $(json-dump-object 'name' $repo_name)
	message_success="Repository '$repo_name' created."
	message_422="Repository name '$repo_name' already exists."
}

github-repo-edit() {
	get-args *key_value_pairs
	require-value repo-name "$repo"
	require-value user-name "$user"
	key_value_pairs+=(name "$repo_name")
	api-patch "/repos/$user_name/$repo_name" "$(json-dump-object-pairs)"
}

github-repo-delete() {
	get-args repo
	check-user-repo "$repo"
	require-value repo-name "$repo"
	require-value user-name "$user"
	api-delete "/repos/$user_name/$repo_name"
	message_success="Repository '$repo_name' deleted"
}

github-collab-list() {
	get-args user-repo
	require-value repo-name "$repo"
	require-value user-name "$user"
	page_size=100
	per_page=$list_count
	[ $per_page -gt $page_size ] && per_page=$page_size
	api-get "/repos/$user_name/$repo_name/collaborators?per_page=$per_page"
	counter=1
}

success-github-collab-list() {
	for ((ii=0; ii < $page_size; ii++)); do
		[ $counter -le $list_count ] || return 0
		name=$(json-get "/$ii/login")
		[ -z "$name" ] && break
		printf "%3d) %s\n" $((counter++)) $name
	done
	if [ $ii -ge $page_size ]; then
		get-next-page success-github-collab-list
	fi
}

github-collab-add() {
	say "*** NOTE *** Can't get collab-add working yet. Patches welcome."
	get-args user-repo *collaborators
	require-value repo-name "$repo"
	require-value user-name "$user"
	for collab_name in ${collaborators[@]}; do
		api-put "/repos/$user_name/$repo_name/collaborators/$collab_name"
	done
}

github-collab-remove() {
	get-args user-repo *collaborators
	require-value repo-name "$repo"
	require-value user-name "$user"
	for collab_name in ${collaborators[@]}; do
		api-delete "/repos/$user_name/$repo_name/collaborators/$collab_name"
	done
}
#------------------------------------------------------------------------------
# API calling functions:
#------------------------------------------------------------------------------
api-get() { api-call GET "$1" "$2"; }
api-post() { api-call POST "$1" "$2"; }
api-put() { api-call PUT "$1" "$2"; }
api-patch() { api-call PATCH "$1" "$2"; }
api-delete() { api-call DELETE "$1" "$2"; }

api-call() {
	[ -n "$repeat_command" ] && api-repeat && return
	require-value api-token "$token"
	local action=$1
	local url=$2
	local data=$3
	local regex="^https?:"
	[[ "$url" =~ $regex ]] || url="$GIT_HUB_API_URI$url"
	# Need to use an array here to preserve whitespace in the JSON.
	[ -n "$data" ] && local data_args=(-d "$data")
	# TODO Figure out how to only specify this complicated command once.
	# The command is very delicate so need tests in place first.
	if [ $GIT_VERBOSE ]; then
		local token=$([ -n "$show_token" ] && echo "$api_token" || echo '********')
		say "  curl -s -S -X$action -H \"Authorization: token $token\" $url $(echo "${data_args[@]}") -D \"$GIT_HUB_HEADER\" > $GIT_HUB_OUTPUT 2> $GIT_HUB_ERROR"
	fi
	[ -n "$dry_run" ] && exit 0
	curl -s -S -X$action -H "Authorization: token $api_token" $url "${data_args[@]}" -D "$GIT_HUB_HEADER" > $GIT_HUB_OUTPUT 2> $GIT_HUB_ERROR
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
# Argument parsing functions:
#------------------------------------------------------------------------------
get-args() {
	local slurp_index=0
    local slurp_re='^\*'
	local user_repo_re='/'
	if [[ "$1" = "user-repo" ]]; then
		if [[ ${command_arguments[0]} =~ $user_repo_re ]]; then
			check-user-repo ${command_arguments[0]}
			unset command_arguments[0]
		fi
		shift
	fi
	for arg in "${command_arguments[@]}"; do
		if [ $slurp_index -gt 0 ]; then
			eval ${1/\*/}[$slurp_index]=\"$arg\"
			: $((slurp_index++))
		elif [ $# -gt 0 ]; then
			if [[ $1 =~ $slurp_re ]]; then
				eval ${1/\*/}[$slurp_index]=\"$arg\"
				: $((slurp_index++))
			else
				eval $1="$arg"
				shift
			fi
		else
			die "Unknown argument: $arg"
		fi
	done
}

check-user-repo() {
	[[ $1 =~ "/" ]] && user-repo ${1/\// }
	true
}

user-repo() {
	user=$1
	repo=$2
}

get-next-page() {
    local callback=$1
	regexp='Link: <(https:.+?)>; rel="next"'
	[[ "$(< $GIT_HUB_HEADER)" =~ $regexp ]] || return
	local link=${BASH_REMATCH[1]}
	api-get "$link"
	if OK; then
		json-load-cache "$(< $GIT_HUB_OUTPUT)"
		$callback
	fi
}

# Usage: require-value variable-name "possible-user-value"
#   Fetch $variable_name or die
require-value() {
	local key=$1
	local var=${key//-/_}
	fetch-value "$@"
	if [ -z "$(eval echo \$$var)" ]; then
		[ "$var" = "api_token" ] && die_need_api_token
		die "Can't find value for '$var'"
	fi
	true
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

	[ -n "$(eval echo \$$var)" ] && return
	eval $var="$2"
	[ -n "$(eval echo \$$var)" ] && return
	eval $var=\"\$$env\"
	[ -n "$(eval echo \$$var)" ] && return
	if [ "$var" = "repo_name" -o "$var" = "user_name" ]; then
		if [ -f ".git/config" ]; then
			url=$(git config --file=.git/config remote.origin.url)
			if [ -n "$url" ]; then
				local re1='github\.com'
				if [[ "$url" =~ $re1 ]]; then
					local re2='^.*[:/](.*)/(.*)\.git$'
					if [[ "$url" =~ $re2 ]]; then
						: ${user_name:="${BASH_REMATCH[1]}"}
						: ${repo_name:="${BASH_REMATCH[2]}"}
						return
					fi
				fi
			fi
		fi
	fi
	eval $var=$(git config --file=$config_file github.$key || echo '')
	[ -n "$(eval echo \$$var)" ] && return
	true
}

#------------------------------------------------------------------------------
# Detailed error messages:
#------------------------------------------------------------------------------
die_need_api_token() {
	cat <<eos

Can't determine your API Access Token. Usually this means you haven't set up
your ~/.githubconfig file yet.

First go to https://github.com/settings/applications and retrieve or create a
Personal API Access Token. This is a 40 digit hexadecimal character string.

Next, run these commands:

	git hub config api-token <your-personal-api-access-token>
	git hub config user-name <your-github-login-id>

Now you should be set up to run most commands. Some commands require that you
add certain 'scopes' to your token.

eos
	die
}

#------------------------------------------------------------------------------
# JSON support functions:
#------------------------------------------------------------------------------
# Format a JSON object from an input list of key/value pairs.
json-dump-object() {
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

# Format a JSON object from an array.
json-dump-object-pairs() {
	local json='{'
	for ((i = 0; i < ${#key_value_pairs[@]}; i = i+2)); do
		local value=${key_value_pairs[$((i+1))]}
		json="$json\"${key_value_pairs[$i]}\":\"$value\""
		if [ $((${#key_value_pairs[@]} - $i)) -gt 2 ]; then
			json="$json,"
		fi
	done
	json="$json}"
	echo $json
}

json-load-cache() {
	json_load_data_cache=$(echo "$1" | tokenize | parse)
}

json-get() {
	local key="^$1\s"
	local data="$2"
	[ -z "$data" ] && data="$json_load_data_cache"
	value=$(echo "$data" | egrep $key | cut -f2)
	if [ "$value" = 'null' ]; then
		echo ''
	else
		echo ${value//\"/}
	fi
}

#------------------------------------------------------------------------------
# Report formatting functions:
#------------------------------------------------------------------------------
report-value() {
	local value=$(json-get "/$1")
	local label=$(eval echo \$label_$1)
	if [ -z "$label" ]; then
		label=$(echo "$1" | tr '_' ' ')
		label=${label//ssh/SSH}
		label=${label//url/URL}
		label=$(for word in $label; do title=`echo "${word:0:1}" | tr a-z A-Z`${word:1}; echo -n "$title "; done)
	fi
	if [ -n "$label" -a -n "$value" ]; then
		printf "%-15s %s\n" "$label" "$value"
	fi
}

label_login='ID'
label_email='Email Address'
label_blog='Web Site'

#------------------------------------------------------------------------------
# Initial setup functions:
#------------------------------------------------------------------------------
assert-env() {
	GIT_CORE_PATH=$(git --exec-path) || exit $?
	PATH=$GIT_CORE_PATH:$PATH

	: ${GIT_HUB_API_URI:=https://api.github.com}
	: ${GIT_HUB_TMP_DIR:=/tmp}
	GIT_HUB_TMP_PREFIX=$GIT_HUB_TMP_DIR/git-hub
	GIT_HUB_INPUT=$GIT_HUB_TMP_PREFIX-in-$$
	GIT_HUB_OUTPUT=$GIT_HUB_TMP_PREFIX-out-$$
	GIT_HUB_ERROR=$GIT_HUB_TMP_PREFIX-err-$$
	GIT_HUB_HEADER=$GIT_HUB_TMP_PREFIX-head-$$
	local cmd
	for cmd in git curl tr egrep head cut; do
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

	user=; repo=; token=; list_count=10
	GIT_QUIET=; GIT_VERBOSE=; show_token=
	user=; repo=; dry_run=;
	while [ $# -gt 0 ]; do
		local option="$1"; shift
		case "$option" in
			--user) user="$1"; shift ;;
			--repo) repo="$1"; shift ;;
			--token) token="$1"; shift ;;
			-c)	list_count=$1; shift ;;

			-h) usage ;;
			-q) GIT_QUIET="1"
				GIT_VERBOSE=
				;;
			-v) GIT_VERBOSE="1"
				GIT_QUIET=
				;;
			-d) dry_run="1" ;;
			-T) show_token="1" ;;

			--) break ;;

			# Dev options:
			-O) show_output="1" ;;
			-H) show_headers="1" ;;
			-J) show_json="1" ;;
			-x) set -x ;;
			-R) repeat_command="1" ;;

			*) die "Unexpected option: $option" ;;
		esac
	done

    command="$1"; shift
	# Some common command aliases:
	[ "$command" = "user" ] && command="user-info"
	[ "$command" = "repo" ] && command="repo-info"
	[ "$command" = "repos" ] && command="repo-list"

	# TODO find better idiom than 'eval' to global array
	for ((i = 0; i < $#; i++)); do
		eval command_arguments[$i]=\$$((i+1))
	done
}

setup-env() {
    source "$GIT_CORE_PATH/lib/core.bash"
    source "$GIT_CORE_PATH/lib/json.bash"
    if [ -n "$repeat_command" ]; then
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
	[ -n "$dry_run" ] &&
		say '*** NOTE: This is a dry run only. ***'
	true
    # require_work_tree
}

#------------------------------------------------------------------------------
# Begin at the end!
#------------------------------------------------------------------------------
main "$@"

# vim: set tabstop=4 shiftwidth=4 noexpandtab:
