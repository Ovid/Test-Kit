#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

BEGIN {
    package Test::Kit::Tester;
    use Test::More tests => 4;
    require Test::Kit;

    #
    # test composition
    #

    Test::Kit->import('TestIs');

    # Fake our existence
    $INC{'Test/Kit/Tester.pm'} = __FILE__;
}

# Use it once...
package main2;
use Test::Kit::Tester;

ok 1, 'We have Test::More ok...';
IS 42, 21+21, '... and the magical IS on main2';

# ... and use it twice
package main;
use Test::Kit::Tester;

ok 1, 'Still have Test::More ok...';
IS 42, 21+21, '... and the magical IS on main2';
