package ComposedTests;

use strict;
use warnings;

use Test::Kit
  'TestIs',
  'TestIsDeeply',
  '+explain',
  'Test::More' => { exclude => 'is_deeply' };

1;
