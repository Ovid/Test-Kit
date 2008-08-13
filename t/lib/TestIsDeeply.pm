package TestIsDeeply;

use base 'Exporter';
our @EXPORT = 'IS_DEEPLY';
use Test::More ();

sub IS_DEEPLY($$;$) { goto &Test::More::is_deeply }

1;
