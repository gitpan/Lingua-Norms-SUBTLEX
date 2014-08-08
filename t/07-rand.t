use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 2;
use Lingua::Norms::SUBTLEX;
use FindBin;

my $subtlex =
  Lingua::Norms::SUBTLEX->new(dir => $FindBin::Bin, filename => 'data_s.csv');

    
my @random = $subtlex->random_word();
ok(
    scalar @random > 1, 'method \'random_word\' did not return an array, it seems'
);

my $str = $subtlex->random_word();
ok(
    length ($str), 'method \'random_word\' did not return a word of any length, it seems'
);

1;
