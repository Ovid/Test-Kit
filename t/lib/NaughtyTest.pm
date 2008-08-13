package NaughtyTest;

use strict;
use warnings;
use Test::More ();

use base 'Exporter';
our @EXPORT = 'ok';

sub ok {
    Test::More::ok(1, '... NaughtyTest::ok should be callable');
};

1;
