#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

BEGIN {

    package Test::Kit::Tester;
    use Test::More tests => 4;
    require Test::Kit;

    #
    # test conflicts
    #
    eval {
        Test::Kit->import(qw/NaughtyTest Test::More Test::Differences/);
    };
    my $error = $@;
    like $error,
qr/\A\QFunction &ok exported from more than one package:  NaughtyTest, Test::More/,
      'Trying to export conflicting functions should fail';

    #
    # test composition
    #

    Test::Kit->_reset;
    {
        Test::Kit::Tester::ok +Test::Kit->import(
            qw/Test::More Test::Differences/),
          '... and composing non-conflicting packages should succeed';
    }
}
ok 1, '... and the Test::More functions should be exported';
eq_or_diff [ 1, 3 ], [ 1, 3 ], '... as should Test::Differences functions';
