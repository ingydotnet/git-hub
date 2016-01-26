#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;
use FindBin '$Bin';

my $yaml = eval "use YAML::XS; 1";

SKIP: {
    skip "YAML::XS not installed", 1 unless $yaml;
    my $data = YAML::XS::LoadFile("$Bin/../Changes");
    isnt($data, undef, "Changes file valid");
}
