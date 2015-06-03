#!/usr/bin/env perl

use strict;

sub main {
    my ($cmd) = @_;
    my $input = do { local $/; <> };
    $input =~ s/.*?\n= Commands\n//s;
    $input =~ s/(.*?\n== Configuration Commands\n.*?\n)==? .*/$1/s;
    my @list;
    my @repo_cmds;
    while ($input =~ s/.*?^- (.*?)(?=\n- |\n== |\z)//ms) {
        my $text = $1;
        $text =~ /\A(.*)\n/
            or die "Bad text '$text'";
        my $usage = $1;
        $usage =~ s/\A`(.*)`\z/$1/
            or die "Bad usage: '$text'";
        (my $name = $usage) =~ s/ .*//;
        push @list, $name;
        if ($usage =~ m#\Q$name\E \[?\(?(<owner>/)?<repo>#) {
            push @repo_cmds, $name;
        }
    }
    @repo_cmds = sort @repo_cmds;
    @list = sort @list;

    if ($cmd eq "bash") {
        generate_bash(\@list);
    }
    else {
        generate_zsh(\@list, \@repo_cmds);
    }
}

sub generate_zsh {
    my ($list, $repo_cmds) = @_;
    print <<'...';
#compdef git-hub -P git\ ##hub
#description perform GitHub operations

# DO NOT EDIT. This file generated by tool/generate-completion.pl.

if [[ -z $GIT_HUB_ROOT ]]; then
	echo 'GIT_HUB_ROOT is null; has `/path/to/git-hub/init` been sourced?'
	return 3
fi

_git-hub() {
    local curcontext="$curcontext" state line

    _arguments \
        '1: :->subcmd'\
        '*: :->repo'

    case $state in
    subcmd)
...
    print <<"...";
        compadd @$list
    ;;
    repo)
        case \$words[2] in
...
    print " " x 8;
    print join '|', @$repo_cmds;
    print <<'...';
)
            re="^(\w+)/(.*)"
            if [[ $words[3] =~ $re ]];
            then
                username="$match[1]"
                if [[ "$username" != "$lastusername" ]];
                then
                    lastusername=$username
                    reponames=`git hub repos $username --raw`
                fi
                _arguments "2:Repos:($reponames)"
            else
                _arguments "2:Repos:()"
            fi
        ;;
        esac
    ;;
    esac

}

...
}

sub generate_bash {
    my ($list) = @_;
        print <<"...";
#!bash

# DO NOT EDIT. This file generated by tool/generate-completion.pl.

_git_hub() {
  __gitcomp "@$list"
}
...
}

main(shift);
