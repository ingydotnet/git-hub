#!bash

# DO NOT EDIT. This file generated by tool/generate-completion.pl.

_git_hub() {
    local _opts=" -h --help --remote= --branch= --sha= --org= --method= --title= --msg= -c= --count= -a --all -q --quiet -v --verbose -r --raw -j --json -A --use-auth -C --no-cache --token= -d --dryrun -T -O -H -J -R -x"
    local subcommands="cache-clear clone collabs comment config config-keys config-list config-unset follow followers following follows fork forks gist gist-clone gist-delete gist-edit gist-fork gist-get gist-init gist-new gist-star gist-unstar gists git-hub-travis help info irc-enable irc-enable irc-url issue issue-close issue-edit issue-new issue-resolve issues keys keys-add member-add member-get member-remove members notify-list open org org-edit org-get org-members org-repos orgs pr-created pr-diff pr-fetch pr-involves pr-list pr-merge pr-new pr-queue repo repo-delete repo-edit repo-get repo-init repo-new repos scope-add scope-remove scopes search-issues search-repo search-user setup star starred stars team team-delete team-members team-new team-repo-add team-repos teams token-delete token-get token-new tokens trust unfollow unstar untrust unwatch upgrade url user user-edit user-get version watch watchers watching"
    local repocommands="clone collabs comment fork forks issue issue-close issue-edit issue-new issue-resolve issues pr-diff pr-fetch pr-list pr-merge repo repo-delete repo-edit repo-get star stars trust unstar untrust unwatch watch watchers"
    local subcommand="$(__git_find_on_cmdline "$subcommands")"

    if [ -z "$subcommand" ]; then
        # no subcommand yet
        case "$cur" in
        -*)
            __gitcomp "$_opts"
        ;;
        *)
            __gitcomp "$subcommands"
        esac

    else

        # dynamic completions
        local last=${COMP_WORDS[ $COMP_CWORD-1 ]}

        if [[ $last == "--remote" || $cur =~ ^--remote= ]]; then
            local dynamic_comp=`git remote`
            __gitcomp "$dynamic_comp" "" "${cur##--remote=}"
            return
        fi

        case "$cur" in

        -*)
            __gitcomp "$_opts"
            return
        ;;
        esac

        if [[ $subcommand == help ]]; then
            __gitcomp "$subcommands"
            return
        elif [[ $subcommand == "config" || $subcommand == "config-unset" ]]; then
            local config_keys
            config_keys=`git hub config-keys`
            __gitcomp "$config_keys"
            return
        fi

        local repocommand="$(__git_find_on_cmdline "$repocommands")"
        if [ -n "$repocommand" ]; then

            local repo_to_complete="$cur"
            if [[ "$repo_to_complete" == "" || "$repo_to_complete" == "@" ]]; then
                local login=`git hub config login`
                COMPREPLY=("$login/")
                return
            elif [[ "$repo_to_complete" =~ ^@/ || "$repo_to_complete" =~ ^/ ]]; then
                local login=`git hub config login`
                repo_to_complete="${repo_to_complete/\@}"
                repo_to_complete="$login""$repo_to_complete"
            elif [[ "$repo_to_complete" =~ ^@.+/ ]]; then
                repo_to_complete="${repo_to_complete/\@}"
            elif [[ "$repo_to_complete" =~ ^([a-zA-Z0-9_-]+)$ ]]; then
                local login=`git hub config login`
                repo_to_complete="$login/$repo_to_complete"
            fi

            # note: username completion works only for lowercase at the
            # moment. usernames with uppercase letters will be lowercased
            if [[ "$repo_to_complete" =~ ^@([a-z0-9_][a-z0-9_-]+) ]];
            then
                # git hub repo @foo<TAB>
                local username="${BASH_REMATCH[1]}"
                # first, check the cache
                local cached
                __git_hub_try_cache "user" "$username"
                local users=("${cached[@]}")
                if [[ -z "$cached" ]]; then
                    # nothing in cache
                    # echo $'\n'"Completing usernames..."
                    users=( $(git hub search-user "$username in:login" --raw --count 100 | tr '[:upper:]' '[:lower:]' | sed -e 's/^/@/' ) )
                fi
                local comp="${users[@]}"
                COMPREPLY=( $( compgen -W "$comp" -- "@$username" ) )
                local count=${#COMPREPLY[@]}
                if [[ $count -eq 1 ]]; then
                    local user="${COMPREPLY[0]}"
                    user="${user/\@/}"
                    COMPREPLY=("$user/")
                fi
                if [[ -z "$cached" ]]; then
                    __git_hub_save_user_cache "$username"
                fi

            else
                local username reponame
                if [[ "$repo_to_complete" =~ ^([a-zA-Z0-9_-]+)/(.*) ]];
                then
                    # git hub repo foobar/<TAB>
                    username="${BASH_REMATCH[1]}"
                    reponame="${BASH_REMATCH[2]}"
                else
                    # git hub repo foobar<TAB>
                    username=`git hub config login`
                    reponame="$repo_to_complete"
                fi

                # first, check the cache
                local cached
                __git_hub_try_cache "repo" "$username/$reponame"
                local reponames=("${cached[@]}")
                if [[ -z "$cached" ]]; then
                    # nothing in cache
                    # echo $'\n'"Completing reponames..."
                    reponames=( $( git hub search-repo "$reponame user:$username in:name fork:true" --raw --count 100 ) )
                    __git_hub_save_repo_cache "$username/$reponame"
                fi
                local comp="${reponames[@]}"
                COMPREPLY=( $( compgen -W "$comp" -- "$username/$reponame" ) )

            fi

        fi

    fi
}

__git_hub_save_repo_cache() {
    __git_hub_last_repo="$1"
    __git_hub_last_repo_result=("${reponames[@]}")
}

__git_hub_save_user_cache() {
    __git_hub_last_user="$1"
    __git_hub_last_user_result=("${users[@]}")
}

__git_hub_try_cache() {
    local cachetype="$1"
    local name="$2"
    local last="__git_hub_last_$cachetype"
    local last_result="__git_hub_last_${cachetype}_result"
    # if we got 100 results that means that there were probably more, so the
    # result is incomplete. We only return this cached result if the
    # key equals the cache key from last time.
    local key="${!last}"
    local result
    if [[ $cachetype == user ]]; then
        result=("${__git_hub_last_user_result[@]}")
    elif [[ $cachetype == repo ]]; then
        result=("${__git_hub_last_repo_result[@]}")
    fi
    if [[ "$key" == "$name" \
        || ( "${name:0:${#key}}" == "$key" \
        && ${#result[@]} -lt 100 \
        ) ]]; then
        cached=("${result[@]}")
    fi
}
