package Test::Kit::Features;

use strict;
use warnings;
use Carp ();

=head1 DESCRIPTION

C<Test::Kit::Features> - Features available for C<Test::Kit>.

=cut

use base 'Test::Builder::Module';

my %method_for = ( explain => \&_setup_explain, );

sub _setup_features {
    my ( $class, $features, @args ) = @_;
    my $callpack = caller(1);

    foreach my $feature (@$features) {
        if ( my $method = $method_for{$feature} ) {
            @args = $class->$method( $callpack, @args );
        }
        else {
            Carp::croak("Unknown feature ($feature) requested");
        }
    }
    return @args;
}

sub _setup_explain {
    my ( $class, $callpack, @args ) = @_;

    my $explain = "$callpack\::explain";
    no strict 'refs';
    *$explain = sub {
        return unless $ENV{TEST_VERBOSE};
        Test::More::diag(
            map {
                ref $_
                  ? do {
                    require Data::Dumper;
                    no warnings 'once';
                    local $Data::Dumper::Indent   = 1;
                    local $Data::Dumper::Sortkeys = 1;
                    local $Data::Dumper::Terse    = 1;
                    Data::Dumper::Dumper($_);
                  }
                  : $_
              } @_
        );
    };
    return @args;
}

1;
