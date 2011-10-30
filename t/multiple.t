#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

BEGIN {
    package Test::Kit::Tester1;
    use Test::More tests => 2;
    require Test::Kit;

    ## Only Test::More
    Test::Kit->import;

    # Fake our existence
    $INC{'Test/Kit/Tester1.pm'} = __FILE__;


    package Test::Kit::Tester2;
    
    ## Only Test::More + TestIs
    Test::Kit->import('TestIs');
    
    # Fake our existence
    $INC{'Test/Kit/Tester2.pm'} = __FILE__;
}


use Test::Kit::Tester1;
use Test::Kit::Tester2;

ok 1, '... the Test::More functions should be exported';
IS 42, 21+21, '... and IS too';
