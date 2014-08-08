use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use Lingua::Norms::SUBTLEX;
my $subtlex =
  Lingua::Norms::SUBTLEX->new(dir => $FindBin::Bin, filename => 'data_s.csv');

ok( $subtlex->is_normed( string => 'cat' ) == 1,
    '\'cat\' returned as not a word' );
ok( $subtlex->is_normed( string => 'cet' ) == 0, '\'cet\' returned as a word' );

1;