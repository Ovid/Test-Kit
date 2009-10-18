#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';
use ComposedTests tests => 8;

IS 3, 3, 'This is from Test::More';
IS_DEEPLY [1], [1], 'This is from Test::Differences';
ok !defined &is_deeply, "... and Test::More::is_deeply should be excluded";
ok defined &use_ok,
  "... but non-excluded Test::More functions should be available";
ok defined &explain, '... and explain should be included';
ok defined &on_fail, '... on_fail should be exported';
on_fail { die "I failed with " . $_[0]->name . " on line " . $_[0]->line };
TODO: {
    local $TODO = 'testing';
    ok 0;
}
ok 1;
