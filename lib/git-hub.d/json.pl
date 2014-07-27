use strict;

my $JSON;
for ( qw/JSON::MaybeXS JSON JSON::PP/ ) {
  last if $JSON = eval "use $_; '$_'";
}

$JSON or die <<'...';

ERROR: No JSON Perl modules are installed.

This Perl program is being used to speed up the 'git-hub' command. It requires
one of the 'JSON::MaybeXS', 'JSON' or 'JSON::PP' Perl modules, but it seems
that you have none of these installed.

Please install the 'JSON::MaybeXS' module from CPAN, and try again.

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
