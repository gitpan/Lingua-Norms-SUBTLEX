
use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 4;
use FindBin;

BEGIN {
    use_ok('Lingua::Norms::SUBTLEX') || print "Bail out!\n";
}

diag(
"Testing Lingua::Norms::SUBTLEX $Lingua::Norms::SUBTLEX::VERSION, Perl $], $^X"
);

my $freq;

eval {
    $freq =
      Lingua::Norms::SUBTLEX->new(
        dir => $FindBin::Bin, filename => 'data_s.csv' );
};
ok( !$@, $@ );

# don't test new() without args because data.csv won't yet be in configlib

# ensure we have a directory:
ok( -d $freq->{'dir'},
    'Could not determine a directory with the sample data file' );

# ensure we have a readable path to file:
ok( -f $freq->{'path'}, 'Could not determine path to sample data file' );

1;
