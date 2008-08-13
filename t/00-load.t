#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Kit' );
}

diag( "Testing Test::Kit $Test::Kit::VERSION, Perl $], $^X" );
