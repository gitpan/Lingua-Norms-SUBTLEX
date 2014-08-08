package Lingua::Norms::SUBTLEX;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use File::Spec;
use Statistics::Lite qw(max mean median stddev);
use String::Util qw(hascontent nocontent);
use Config;

$Lingua::Norms::SUBTLEX::VERSION = '0.01';

=head1 NAME

Lingua::Norms::SUBTLEX - Retrieve frequency values and frequency-based lists from Brysbaert Subtitles Corpus

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

 # the basics:
 use Lingua::Norms::SUBTLEX;
 my $subtlex = Lingua::Norms::SUBTLEX->new();
 my $bool = $subtlex->is_normed(string => 'fuip'); # isa_word ? 
 my $frq = $subtlex->freq(string => 'frog'); # freq. per million, or get log/zipf
 my $href = $subtlex->freqhash(words => [qw/frog fish ape/]); # freqs. for a list of words
 say "$_ freq per mill = $href->{$_}" for keys %{$href};

 # stats, parts-of-speech, orthographic relations:
 say "mean freq per mill = ", $subtlex->mean_freq(words => [qw/frog fish ape/]); # or median, std-dev.
 say "frog part-of-speech = ", $subtlex->pos(string => 'frog');
 my ($count, $orthons_aref) = $subtlex->on_count(string => 'frog'); # or scalar context for count only; or freq_max/mean
 say "orthon of frog = $_" for @{$orthons_aref}; # e.g., from
 
 # retrieve (list of) words to certain specs:
 my $aref = $subtlex->list_words(freq => [2, 400], onc => [1,], length => [4, 4], cv_pattern => 'CCVC', regex => '^f');
 my $string = $subltex->random_word();

=head1 DESCRIPTION

The SUBTLEX-US word-frequency list comprises 74,286 letter-strings, with their frequencies of occurrence and parts-of-speech, based on a corpus of some 30 million words from film and television subtitles. For details, see L<http://expsy.ugent.be/subtlexus/|http://expsy.ugent.be/subtlexus/> to download the file and install it, and L<REFERENCES|Lingua::Norms::SUBTLEX/REFERENCES>. Only a small sample from the SUBTLEX-US list is included in the installation distribtuion used for testing purposes (or the archive would be about 2 MB, and testing would take about 35 secs). The complete file should be downloaded, named "US_2007.csv", and placed in an appropriate directory, with its location specified in object construction, as described below. Other language files from this project might be supported by this module but have not been tested to date.

=head1 SUBROUTINES/METHODS

All methods are called via the class object, and with named (hash of) arguments, usually B<string>, where relevant.

=head2 new

 $subtlex = Lingua::Norms::SUBTLEX->new();
 $subtlex = Lingua::Norms::SUBTLEX->new(dir => 'file_location'); # where US_2007.csv is located
 $subtlex = Lingua::Norms::SUBTLEX->new(dir => 'file_location', filename => 'foo'); # where datafile is located

Returns a class object for accessing the other methods. An optional argument B<dir> can be given to specify the directory in which the SUBTLEX table is stored. If this is not specified, then the "Lingua/Norms/SUBTLEX" directory within the 'sitelib' configured for the local Perl installation is assumed to be the location (i.e., using Config.pm, and where the sample file should have been stored upon installation of the module). The method will C<croak> if the given B<filename> or the default, "US_2007.csv" in this directory cannot be C<open>ed (or C<close>d). 

=cut

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, ref($class) ? ref($class) : $class;

    # determine database location:
    if ( hascontent( $args{'dir'} ) )
    { # given in this call? if so, check it's a directory before setting it as THE location:
        croak
"Value given to argument 'dir' ($args{'dir'}) in new() is not a directory"
          if !-d $args{'dir'};
        $self->{'dir'} = $args{'dir'};
    }
    else
    { # default location is this module's lowest directory within the configured sitelib:
        $self->{'dir'} =
          File::Spec->catdir( $Config{'sitelib'}, qw/Lingua Norms SUBTLEX/ );
    }

    # Now try opening and reading the file US_2007.csv from within this directory:
    my $filename = $args{'filename'} ? delete $args{'filename'} : 'US_2007.csv';
    my $path = File::Spec->catfile( $self->{'dir'}, $filename );
    croak
"file named $filename does not exist within the directory '$self->{'dir'}'. Maybe you need to download the file (see POD) or re-locate it"
      if !-e $path;

    #my @fields;
    open my $fh, q{<}, $path
      or croak("Cannot open SUBTLEX data file in $self->{'dir'}: $!");

    # -- might need field names (column headings) later:
    #while (<$fh>) {
    #    chomp;
    #    @fields = split/,/;
    #    last; # retain only the column headings, reading in only the first line
    #}
    close $fh or croak("Cannot close word file: $!");
    $self->{'path'} = $path;    # remember the path to the file
         #$self->{'fields'} = [@fields]; # remember the column headings

    return
      $self
      ; # every method accessed by $self now knows where to look for the file, and for its data under the correct headings
}

=head2 Frequencies and POS for individual words or word-lists

=head3 is_normed

 $bool = $subtlex->is_normed(string => $word);

I<Alias>: isa_word

Returns a boolean value to specify whether or not the letter-string passed as B<string> is represented in the SUBTLEX corpus - by simply going line-by-line through the datafile and checking if the given string is identical to the first comma-delimited string on each line. This might be thought of as a lexical decision ("is this string a word?") but note that some very low frequency letter-strings in the corpus would not be considered words in the average context.

=cut

sub is_normed {
    my ( $self, %args ) = @_;
    croak 'No word to test; pass a string to the function'
      if nocontent( $args{'string'} );
    my $str = $args{'string'};
    my $res = 0;                 # the boolean value to return from this sub
    open my $fh, q{<}, $self->{'path'} or croak $!;
    while (<$fh>) {
        next if $. == 1;         # skip headings
        /^([^,]+)/sxm
        or next  ;    # isolate first token ahead of a comma as $1 in this csv file
        if ( $str eq $1 ) {    # first token equals given string?
            $res = 1;          # set result to return as true
            last;              # got it, so abort the look-up
        }
    }
    close $fh or croak $!;
    return $res;               # zero if the string was not found in the file
}
*isa_word = \&is_normed;

=head3 freq

 $frq = $subtlex->freq(string => 'aword');

Returns frequency per million for the word passed as B<string>, or the empty-string if the string is not represented in the norms.

=cut

sub freq {
    my ( $self, %args ) = @_;
    croak
      'No word to test; pass a letter-string named \'string\' to the function'
      if !$args{'string'};
    return _get_field( $self, $args{'string'}, 5 );
}

=head3 lfreq

 $lfreq = $subtlex->freq(string => 'aword');

Returns log frequency per million for the word passed as B<string>, or the empty-string if the string is not represented in the norms.

=cut

sub lfreq {
    my ( $self, %args ) = @_;
    croak
      'No word to test; pass a letter-string named \'string\' to the function'
      if !$args{'string'};
    return _get_field( $self, $args{'string'}, 6 );
}

=head3 zipf

 $zipf = $subtlex->zipf(string => 'aword');

Returns zipf frequency for the word passed as B<string>, or the empty-string if the string is not represented in the norms. See Van Heuven et al. (in press) and L<http://crr.ugent.be/archives/1352|http://crr.ugent.be/archives/1352>.

=cut

sub zipf {
    my ( $self, %args ) = @_;
    croak
      'No word to test; pass a letter-string named \'string\' to the function'
      if !$args{'string'};
    return _get_field( $self, $args{'string'}, 14 );
}

=head3 freqhash

 $href = $subtlex->freqhash(strings => [qw/word1 word2/], scale => raw|log|zipf);

Returns frequency as a reference to a hash for the words passed as B<strings>; e.g., {string1 => number, string2 => number, ...}. By default, the values in the hash are corpus frequency per million. If the optional argument B<scale> is defined, and it equals I<log>, then the values are log-frequency; similarly, I<zipf> yields zip-frequency. 

=cut

sub freqhash {
    my ( $self, %args ) = @_;
    croak
'No string(s) to test; pass one or more letter-strings named \'strings\' as a referenced array to the function freqhash()'
      if !$args{'strings'};
    my $strs =
      ref $args{'strings'}
      ? $args{'strings'}
      : croak 'No reference to an array of letter-strings found';
    my $field_i = '';
    if ( hascontent( $args{'scale'} ) ) {
        if ( $args{'scale'} eq 'log' ) {
            $field_i = 6;
        }
        elsif ( $args{'scale'} eq 'zipf' ) {
            $field_i = 14;
        }
        else {
            $field_i = 5;
        }
    }
    else {
        $field_i = 5;
    }

    my %frq = ();
    foreach my $str ( @{$strs} ) {
        $frq{ lc($str) } = [ undef, $str ];
    }
    open my $fh, q{<}, $self->{'path'} or croak "$!\n";
    while (<$fh>) {
        next if $. == 1;
        chomp;
        my @line = split /,/sxm, $_;
        my ( $dstr, $val ) = ( $line[0], $line[$field_i] );
        if ( exists $frq{ lc($dstr) } ) {
            $frq{ lc($dstr) }->[0] = $val;
        }
    }
    close $fh or croak $!;
    my %frq_origs = ();
    foreach my $val ( values %frq ) {
        $frq_origs{ $val->[1] } = $val->[0];
    }
    return \%frq_origs;
}

=head3 pos

 $pos_str = $subtlex->pos(string => 'aword');

Returns part-of-speech string for a given word, as per Brysbaert, New & Keuleers (2012). The return value is undefined if the word is not found.

=cut

sub pos {
    my ( $self, %args ) = @_;
    croak 'No words to test' if !$args{'string'};
    my $word = $args{'string'};
    my $pos;
    open my $fh, q{<}, $self->{'path'} or croak "$!\n";
    while (<$fh>) {
        next if $. == 1;    # skip column heading line
        /^([^,]+)/sxm;
        if ( $word eq $1 ) {
            chomp;
            my @line = split /,/sxm, $_;
            $pos = $line[9];
            last;
        }
    }
    close $fh;
    return $pos;
}

=head2 Descriptive frequency statistics for lists

These methods return a descriptive statistic (mean, median or standard deviation) for a list of B<strings>. Like L<freq_hash|Lingua::Norms::SUBTLEX/freq_hash>, they take an optional argument B<scale> to specify if the returned values should be raw frequencies per million, log frequencies, or zip-frequencies.

=head3 mean_freq

 $mean = $subtlex->mean_freq(strings => [qw/word1 word2/], scale => 'raw|log|zipf');

Returns the arithmetic mean of the frequencies for the given B<words>, or mean of the log frequencies if B<log> => 1.

=cut

sub mean_freq {
    my ( $self, %args ) = @_;
    my $href = $self->freqhash(%args);
    return mean( values %{$href} );
}

=head3 median_freq

 $median = $subtlex->median_freq(words => [qw/word1 word2/], scale => 'raw|log|zipf');

Returns the median of the frequencies for the given B<words>, or median of the log frequencies if B<log> => 1.

=cut

sub median_freq {
    my ( $self, %args ) = @_;
    my $href = $self->freqhash(%args);
    return median( values %{$href} );
}

=head3 sd_freq

 $sd = $subtlex->sd_freq(words => [qw/word1 word2/], scale => 'raw|log|zipf');

Returns the standard deviation of the frequencies for the given B<words>, or standard deviation of the log frequencies if B<log> => 1.

=cut

sub sd_freq {
    my ( $self, %args ) = @_;
    my $href = $self->freqhash(%args);
    return stddev( values %{$href} );
}

=head2 Orthographic neighbourhood measures

These methods return stats re the orthographic relatedness of a specified letter-B<string> to words in the SUBTLEX corpus. Unless otherwise stated, an orthographic neighbour here means letter-strings that are identical except for a single-letter substitution while holding string-length constant, i.e., the Coltheart I<N> of a letter-string, as defined in Coltheart et al. (1977). These measures are calculated in realtime; they are not listed in the datafile for look-up, so expect some extra-normal delay in getting a returned value.

=head3 on_count

 $n = $subtlex->on_count(string => $letters);
 ($n, $orthons_aref) = $subtlex->on_count(string => $letters);

Returns orthographic neighbourhood count (Coltheart I<N>) within the SUBTLEX corpus. Called in array context, also returns a reference to an array of the neighbours retrieved, if any.

=cut

sub on_count {
    my ( $self, %args ) = @_;
    croak 'No words to test' if !$args{'string'};
    my $word = lc( $args{'string'} );
    require Lingua::Orthon;
    my $ortho = Lingua::Orthon->new();
    my ( $z, @orthons ) = (0);
    open my $fh, q{<}, $self->{'path'} or die "$!\n";
    while (<$fh>) {
        next if $. == 1;    # skip column heading line
        /^([^,]+)/sxm or next; 
        my $test = lc($1);
        if ( $ortho->are_orthons( $word, $test ) ) {
            push @orthons, $test;
            $z++;
        }
    }
    close $fh;
    return wantarray ? ( $z, \@orthons ) : $z;
}

=head3 on_freq_max

 $m = $subtlex->on_freq_max(string => $letters);

Returns the maximum SUBTLEX frequency per million among the orthographic neighbours (per Coltheart I<N>) of a particular letter-string. If (unusually) all the frequencies are the same, then that value is returned. If the string has no (Coltheart-type) neighbours, undef is returned.

=cut

sub on_freq_max {
    my ( $self, %args ) = @_;
    croak 'No words to test' if !$args{'string'};
    my $frq_aref = _get_orthon_f( $args{'string'}, $self->{'path'}, 5 );
    return scalar @{$frq_aref} ? max( @{$frq_aref} ) : undef;
}

=head3 on_freq_mean

 $m = $subtlex->on_freq_mean(string => $letters);

Returns the mean SUBTLEX frequencies per million of the orthographic neighbours (per Coltheart I<N>) of a particular letter-string. If the string has no (Coltheart-type) neighbours, undef is returned. 

=cut

sub on_freq_mean {
    my ( $self, %args ) = @_;
    croak 'No words to test' if !$args{'string'};
    my $frq_aref = _get_orthon_f( $args{'string'}, $self->{'path'}, 5 );
    return scalar @{$frq_aref} ? mean( @{$frq_aref} ) : undef;
}

=head3 on_lfreq_mean

 $m = $subtlex->on_lfreq_mean(string => $letters);

Returns the mean log of SUBTLEX frequencies of the orthographic neighbours (per Coltheart I<N>) of a particular letter-string. If the string has no  (Coltheart-type) neighbours, undef is returned.

=cut

sub on_lfreq_mean {
    my ( $self, %args ) = @_;
    croak 'No words to test' if !$args{'string'};
    my $frq_aref = _get_orthon_f( $args{'string'}, $self->{'path'}, 6 );
    return scalar @{$frq_aref} ? mean( @{$frq_aref} ) : undef;
}

=head3 on_zipf_mean

 $m = $subtlex->on_zipf_mean(string => $letters);

Returns the mean zipf of SUBTLEX frequencies of the orthographic neighbours (per Coltheart I<N>) of a given letter-string. If the string has no (Coltheart-type) <b></b>neighbours, undef is returned.

=cut

sub on_zipf_mean {
    my ( $self, %args ) = @_;
    croak 'No words to test' if !$args{'string'};
    my $frq_aref = _get_orthon_f( $args{'string'}, $self->{'path'}, 14 );
    return scalar @{$frq_aref} ? mean( @{$frq_aref} ) : undef;
}

=head3 on_ldist

 $m = $subtlex->on_ldist(string => $letters, lim => 20);

I<Alias>: ldist

Returns the mean L<Levenshtein Distance|http://www.let.rug.nl/%7Ekleiweg/lev/levenshtein.html> from a word to its B<lim> closest orthographic neighbours. The default B<lim>it is 20, as defined in Yarkoni et al. (2008). The module uses the matrix-based calculation of Levenshtein Distance as implemented in this author's L<Lingua::Orthon|Lingua::Orthon> module. No defined value is returned if no Levenshtein Distance is found (whereas zero would connote "identical to everything").

=cut

sub on_ldist {
    my ( $self, %args ) = @_;
    croak 'No words to test' if !$args{'string'};
    $args{'lim'} ||= 20;
    my $frq_aref =
      _get_orthon_ldist( $args{'string'}, $self->{'path'}, $args{'lim'} );
    return scalar @{$frq_aref} ? mean( @{$frq_aref} ) : undef;
}
*ldist = \&on_ldist;

=head2 Retrieving letter-strings/words

=head3 list_strings

 $aref = $subtlex->list_words(freq => [1, 20], onc => [0, 3], length => [4, 4], cv_pattern => 'CVCV', regex => '^f');
 $aref = $subtlex->list_words(zipf => [0, 2], onc => [0, 3], length => [4, 4], cv_pattern => 'CVCV', regex => '^f');

I<Alias>: list_words

Returns a list of words from the SUBTLEX corpus that satisfies certain criteria: minimum and/or maximum letter-length (specified by the named argument B<length>), minimum and/or maximum frequency (argument B<freq>) or zip-frequency (argument B<zipf>), minimum and/or maximum orthographic neighbourhood count (argument B<onc>), a consonant-vowel pattern (argument B<cv_pattern>), or a specific regular expression (argument B<regex>).

For the minimum/maximum constrained criteria, the two limits are given as a referenced array where the first element is the minimum and the second element is the maximum. For example, [3, 7] would specify letter-strings of 3 to 7 letters in length; [4, 4] specifies letter-strings of only 4 letters in length. If only one of these is to be constrained, then the array would be given as, e.g., [3] to specify a minimum of 3 letters without constraining the maximum, or ['',7] for a maximum of 7 letters without constraining the minimum (checking if the element C<hascontent> as per String::Util).

The consonant-vowel pattern is specified as a string by the usual convention, e.g., 'CCVCC' defines a 5-letter word starting and ending with pairs of consonants, the pairs separated by a vowel. 'Y' is defined here as a consonant.

A finer selection of particular letters can be made by giving a regular expression as a string to the B<regex> argument. In the example above, only letter-strings starting with the letter 'f', followed by one of more other letters, are specified. Alternatively, for example, '[^aeiouy]$' specifies that the letter-strings must not end with a vowel (here including 'y'). The entire example for '^f', including the shown arguments for B<cv_pattern>, B<freq>, B<onc> and B<length>, would return only two words: I<fiji> and I<fuse>.

The selection procedure will be made particularly slow wherever B<onc> is specified (as this has to be calculated in real-time) and no arguments are given for B<cv_pattern> and C<regex> (which are tested ahead of any other criteria).

Syllable-counts might be added in future; existing algorithms in the Lingua family are not sufficiently reliable for the purposes to which the present module might often be put; an alternative is being worked on.

The value returned is always a reference to the list of words retrieved (or to an empty list if none was retrieved).

=cut

sub list_strings {
    my ( $self, %args ) = @_;

    # set criteria:
    my ( $min, $max ) = ();
    if ( ref $args{'freq'} ) {
        ( $min, $max ) = _set_minmax( $args{'freq'} );
    }
    elsif( ref $args{'zipf'}) {
     ( $min, $max ) = _set_minmax( $args{'zipf'} );
    }

    my $regex;
    if ( hascontent( $args{'regex'} ) ) {
        $regex = qr/$args{'regex'}/sxm;
    }
    my $cv_patt;
    if ( hascontent( $args{'cv_pattern'} ) ) {
        my $tmp = '';
        my @c = split //, uc( $args{'cv_pattern'} );
        foreach (@c) {
            $tmp .= $_ eq 'C' ? '[BCDFGHJKLMNPQRSTVWXYZ]' : '[AEIOU]';
        }
        $cv_patt = qr/^$tmp$/isxm;
    }

    my @list = ();
    open my $fh, q{<}, $self->{'path'} or croak $!;
    while (<$fh>) {
        next if $. == 1;    # skip column heading line
        chomp $_;
        my @line = split /,/sxm, $_;
        next if defined $regex   and $line[0] !~ $regex;
        next if defined $cv_patt and $line[0] !~ $cv_patt;
        my $i =  ref $args{'freq'} ? 5 :  ref $args{'zipf'} ? 14 : ''; 
        if (hascontent($i)) {
            if ( $line[$i] >= $min ) {
                if ( defined $max ) {
                    if ( $line[$i] <= $max ) {
                        push @list, $line[0];
                    } # else don't add - it is greater than min, but not less than max
                }
                else {    # is greater than min, and max is undefined
                    push @list, $line[0];
                }
            }
        }
    }
    close $fh or croak;

    
    if ( ref $args{'length'} ) {
        my (@sub_list) = ();
        my ( $mina, $maxa ) = _set_minmax( $args{'length'} );
        foreach (@list) {
            push @sub_list, $_ if _in_range( length($_), $mina, $maxa );
        }
        @list = @sub_list;
    }

    if ( ref $args{'onc'} ) {
        my ( $n,    @sub_list ) = ();
        my ( $mina, $maxa )     = _set_minmax( $args{'onc'} );
        foreach my $s (@list) {
            $n = $self->on_count( string => $s );
            push @sub_list, $s if _in_range( $n, $mina, $maxa );
        }
        @list = @sub_list;
    }
    return \@list;
}
*list_words = \&list_strings;

=head3 all_strings

 $aref = $subtlex->all_strings();

I<Alias>: all_words

Returns a reference to an array of all letter-strings in the corpus, in their given order.

=cut

sub all_strings {
    my ( $self, %args ) = @_;
    my @list = ();
    open my $fh, q{<}, $self->{'path'} or croak $!;
    while (<$fh>) {
        next if $. == 1;    # skip column heading line
        /^([^,]+)/sxm or next; 
        push @list, $1;
    }
    close $fh or croak;
    return \@list;
}
*all_words = \&all_strings;

=head3 random_string

 $string = $subtlex->random_string();
 @data = $subtlex->random_string();

I<Alias>: random_word

Picks a random line from the corpus, using L<File::RandomLine|File::RandomLine> (except the top header line). Returns the word in that line if called in scalar context; otherwise, the array of data for that line. (A future version might let specifying a match to specific criteria, self-aborting after trying X lines.)

=cut

sub random_string {
    my ( $self, %args ) = @_;
    require File::RandomLine;
    my $rl =
      File::RandomLine->new( $self->{'path'}, { algorithm => 'uniform' } );
    my (@ari) = ();
    while ( not scalar @ari or $ari[0] eq 'Word' ) {
        @ari = split( q{,}, $rl->next );
    }
    if (wantarray) {
        return @ari;
    }
    else {
        return $ari[0];
    }
}
*random_word = \&random_string;

=head2 Miscellaneous

=head3 nlines

Returns the number of lines, less the column headings, in the installed US_2007.csv file used by other methods read.

=cut

sub nlines {
    my $self = shift;
    my $z    = 0;
    open( my $fh, q{<}, $self->{'path'} ) or croak "$!\n";
    while (<$fh>) {
        next if $. == 1;    # skip column heading line
        $z++;
    }
    close $fh or croak $!;
    return $z;
}

### PRIVATMETHODEN:

sub _get_orthon_f {
    my ( $str, $path, $idx ) = @_;
    my $word = lc($str);
    require Lingua::Orthon;
    my $ortho = Lingua::Orthon->new();
    my @freqs = ();
    open( my $fh, q{<}, $path ) or croak $!;
    while (<$fh>) {
        next if $. == 1;    # skip column heading line
        /^([^,]+)/xsm or next;      # capture first token, a word
        my $test = lc($1);
        if ( $ortho->are_orthons( $word, $test ) ) {    # Lingua::Orthon method
            chomp $_;    # remove linebreak from line of data from file <F>
            my @line = split /,/xsm, $_;
            push @freqs, $line[$idx];
        }
    }
    close $fh;
    return \@freqs;
}

sub _get_orthon_ldist {
    my ( $str, $path, $lim ) = @_;
    my $word = lc($str);
    require Lingua::Orthon;
    my $ortho  = Lingua::Orthon->new();
    my @ldists = ();
    my @freqs  = ();
    my $idx    = 5;
    open( my $fh, q{<}, $path ) or croak $!;

    while (<$fh>) {
        next if $. == 1;    # skip column heading line
        /^([^,]+)/sxm or next;
        my $test = lc($1);
        my $ldist = $ortho->ldist( $word, $test );
        if ( ref $ldist and @{$ldist} and $ldist < $ldists[-1] ) {
            pop @ldists;
            push @ldists, @$ldist;
        }
        if ( $ortho->are_orthons( $word, $test ) ) {
            chomp $_;
            my @line = split /,/xsm, $_;
            push @freqs, $line[$idx];
        }
    }
    close $fh;
    return \@freqs;
}

sub _get_field {
    my ( $self, $str, $field_i ) = @_;
    $str = lc($str);
    my $val = '';    # default value returned is empty string
    open( my $fh, q{<}, $self->{'path'} ) or croak $!;
    while (<$fh>) {
        next if $. == 1;    # skip column heading line
        /^([^,]+)/sxm;
        if ( $str eq $1 ) {
            chomp;          # or zipf will return with "\n" appended
            my @line = split /,/sxm, $_;
            $val = $line[$field_i];
            last;
        }
    }
    close $fh or croak;
    return $val;
}

sub _set_minmax {
    my $aref = shift;
    my ( $min, $max ) = ();
    if ( hascontent( $aref->[0] ) ) {
        $min = $aref->[0];
    }
    if ( hascontent( $aref->[1] ) ) {
        $max = $aref->[1];
    }
    return ( $min, $max );
}

sub _in_range {
    my ( $n, $min, $max ) = @_;
    my $res = 1;
    if ( defined $min and $n < $min ) {    # fails min
        $res = 0;
    }
    if ( $res && ( defined $max and $n > $max ) ) {    # fails max and min
        $res = 0;
    }
    return $res;
}

=head1 DIAGNOSTICS

=over 4

=item Value given to argument 'dir' (VALUE) in new() is not a directory

Croaked from new() if called with a value for the argument B<dir>, and this value is not actually a directory/folder. This is where the main file, named US_2007.csv, should be located.

=item US_2007.csv does not exist within the directory 'VALUE'. Maybe you need to download the file (see POD) or re-locate it

Croaked from new() if the given or default directory exists, but the file 'US_2007.csv' cannot be found within it. This is the location of the file that should have been downloaded from the site: L<http://expsy.ugent.be/subtlexus/|http://expsy.ugent.be/subtlexus/>.

=item Cannot open SUBTLEX data file

Croaked when calling L<new|Lingua::Norms::SUBTLEX/new> and a valid path to the US_2007.csv file is not available for opening (and similarly for closing.

=item No word(s) to test; pass a string to the function

Croaked upon a number of methods that expect a value for the named argument B<string>, and when no such value is given, or the string is empty. These methods require the letter-string to be passed to it as a I<key> => I<value> pair, with the key B<string> and the value the string to test.

=back

=head1 DEPENDENCIES

Statistics::Lite

Lingua::Orthon

String::Util

File::RandomLine

=head1 REFERENCES

B<Brysbaert, M., & New, B.> (2009). Moving beyond Kucera and Francis: A critical evaluation of current word frequency norms and the introduction of a new and improved word frequency measure for American English. I<Behavior Research Methods>, I<41>, 977-990. doi: 10.3758/BRM.41.4.977.

B<Brysbaert, M., New, B., & Keuleers,E.> (2012). Adding part-of-speech information to the SUBTLEX-US word frequencies. I<Behavior Research Methods>, I<44>, 991-997.

B<Coltheart, M., Davelaar, E., Jonasson, J. T., & Besner, D.> (1977). Access to the internal lexicon. In S. Dornic (Ed.), I<Attention and performance> (Vol. 6, pp. 535-555). London, UK: Academic.

B<Van Heuven, W. J. B., Mandera, P., Keuleers, E., & Brysbaert, M.> (in press). SUBTLEX-UK: A new and improved word frequency database for British English. I<Quarterly Journal of Experimental Psychology>.

B<Yarkoni, T., Balota, D. A., & Yap, M.> (2008). Moving beyond Coltheart's I<N>: A new measure of orthographic similarity. I<Psychonomic Bulletin and Review>, I<15>, 971-979. doi: 10.3758/PBR.15.5.971.

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-lingua-norms-subtlfreq-0.01 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Norms-SUBTLEX-0.01>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TO DO

=over 4

=item Aliases

Alias for functions? frq, logf ... avoiding debate about how a string is a word or not. making whole module child of Class::Accessor or Moosify.

=item Language

Test with different language norms, adapt if necessary

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Norms::SUBTLEX


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Norms-SUBTLEX-0.01>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-Norms-SUBTLEX-0.01>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-Norms-SUBTLEX-0.01>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-Norms-SUBTLEX-0.01/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of Lingua::Norms::SUBTLEX

