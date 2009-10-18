#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Test::Kit' )           or die;
	use_ok( 'Test::Kit::Features' ) or die;
}

diag( "Testing Test::Kit $Test::Kit::VERSION, Perl $], $^X" );
