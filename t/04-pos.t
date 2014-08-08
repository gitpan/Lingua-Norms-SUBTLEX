use strict;
use warnings;
use Test::More tests => 1;
use Statistics::Lite qw(mean median stddev);
use FindBin;
use Lingua::Norms::SUBTLEX;
my $subtlex =
  Lingua::Norms::SUBTLEX->new(dir => $FindBin::Bin, filename => 'data_s.csv');

ok(
    $subtlex->pos( string => 'aardvark' ) eq 'Noun',
    "'aardvark' POS not returned as Noun"
);

1;
