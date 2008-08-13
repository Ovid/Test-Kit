#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';
use ComposedTests 'no_plan';  #tests => 2;

IS 3, 3 , 'This is from Test::More';
IS_DEEPLY [1],[1], 'This is from Test::Differences';
explain [qw/foo bar/];
ok !defined &is_deeply, 
    "... and Test::More::is_deeply should be excluded";
ok defined &use_ok,
    "... but non-excluded Test::More functions should be available";
