use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::Norms::SUBTLEX',
    license             => 'perl',
    dist_author         => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from   => 'lib/Lingua/Norms/SUBTLEX.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4007',
        'Statistics::Lite' => '3.2',
        'Lingua::Orthon' => '0.01',
    },
    build_requires => {
        'Test::More' => '0.92',
        'File::Spec' => '0.20',
        'File::RandomLine' => '0.20',
        'Statistics::Lite' => '3.2',
        'Array::Compare' => '2.02',
        'Lingua::Orthon' => '0.01',
        'FindBin' => 0,
    },
    requires => {
        'File::Spec' => '0.20',
        'Statistics::Lite' => '3.2',
        'File::RandomLine' => '0.20',
        'String::Util' => 0,
        'Config' => 0,
        'Lingua::Orthon' => '0.01',
    },
    add_to_cleanup     => [ 'Lingua-Norms-SUBTLEX-0.01-*' ],
    create_makefile_pl => 'traditional',
);
$builder->add_build_element('csv');
$builder->create_build_script();
