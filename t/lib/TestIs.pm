package TestIs;

use base 'Exporter';
our @EXPORT = 'IS';
use Test::More ();

sub IS($$;$) { goto &Test::More::is }

1;
