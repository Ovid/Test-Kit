use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::Kit',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Test/Kit.pm',
    build_requires    => { 
        'Test::Differences' => 0.48,
    },
    requires          => {
        'Test::More'       => 0,
        'base'             => 2.11,
        'namespace::clean' => 0.08,
    },
    add_to_cleanup     => ['Test-Kit-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
