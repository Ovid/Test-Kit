#!/usr/bin/perl

use strict;
use warnings;
no warnings 'once';
use lib 't/lib';
use Test::More tests => 3;
require Test::Kit;

# trying to use an unknown module

eval { Test::Kit->import('No::Such::Module') };
my $error = $@;
like $error, qr/Cannot require No::Such::Module/,
    'Trying to use a non-existent test module should fail';

# we had an import method exported by Test::Kit, so make sure we fail with it

eval { Test::Kit->import('Test::More') };
$error = $@;
like $error, qr/Class main must not define an &import method/,
    '... or when you already have an import method defined';

# trying to use unknown definition keys
undef *main::import;
eval {
    Test::Kit->import('Test::More' => { unknown_definition => 1 });
};
$error = $@;
like $error, qr/Uknown keys in module definition: unknown_definition/,
    '... and trying to use unknown keys in definitions should fail';
