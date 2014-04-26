use strict;

my $JSON;
for ( qw/JSON JSON::PP/ ) {
  last if $JSON = eval "use $_; '$_'";
}

$JSON or die <<'...';

ERROR: 'JSON.pm' Perl module not installed.

This Perl program is being used to speed up the 'git-hub' command. It requires
the 'JSON' Perl module, but it seems that you don't have it installed.

Please install the 'JSON' module from CPAN, and try again.

For extra speed, you can also install the 'JSON::XS' module.

...

{
  my $data = decode_json(do {local $/; <>});
  die "Unknown JSON result" unless
    ref($data) =~ /^(HASH|ARRAY)$/;
  walk($data, '');
};

sub walk {
  my ($node, $path) = @_;
  if (ref($node) eq 'HASH') {
    for my $key (keys %$node) {
      walk($node->{$key}, "$path/$key");
    }
  }
  elsif (ref($node) eq 'ARRAY') {
    for (my $i = 0; $i < @$node; $i++) {
      walk($node->[$i], "$path/$i");
    }
  }
  else {
    my $value = encode_json([$node]);
    print "$path\t", substr($value,1,-1), "\n";
  }
}
