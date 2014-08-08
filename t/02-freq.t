use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 12;
use FindBin;
use Lingua::Norms::SUBTLEX;

my $subtlex = Lingua::Norms::SUBTLEX->new(dir => $FindBin::Bin, filename => 'data_s.csv');
my $val;
my %testlist = (
    the       => { freq => 29449.18, log => 6.1766, zipf => 7.468477762 },
    Detective => { freq => 61.12, log => 3.4939, zipf => 4.785710253 }
);

while (my($key, $val) = each %testlist) {
    ok ($subtlex->freq(string => $key) == $val->{'freq'}, "'$key' returned wrong frequency");
    ok ($subtlex->lfreq(string => $key) == $val->{'log'}, "'$key' returned wrong log frequency");
    ok ($subtlex->zipf(string => $key) == $val->{'zipf'}, "'$key' returned wrong zip frequency");
}

my $href = $subtlex->freqhash(strings => [keys %testlist]);
while (my($key, $val) = each %testlist) {
    ok ($href->{$key} == $val->{'freq'}, "'$key' returned wrong frequency");
}
$href = $subtlex->freqhash(strings => [keys %testlist], scale => 'log');
while (my($key, $val) = each %testlist) {
    ok ($href->{$key} == $val->{'log'}, "'$key' returned wrong log frequency");
}
$href = $subtlex->freqhash(strings => [keys %testlist], scale => 'zipf');
while (my($key, $val) = each %testlist) {
    ok ($href->{$key} == $val->{'zipf'}, "'$key' returned wrong zip frequency");
}
#, scale => raw|log|zipf

1;