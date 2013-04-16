package Test::Kit::Features;

use strict;
use warnings;
use Carp ();

=head1 DESCRIPTION

C<Test::Kit::Features> - Features available for C<Test::Kit>.

=head1 VERSION

Version 0.100

=cut

our $VERSION = '0.100';
$VERSION = eval $VERSION;

=head2 C<explain>

 use Test::Kit '+explain';

This exports an C<&explain> function into your namespace.  It's like C<&diag>,
but only runs if your tests are being run in verbose mode C<prove -v>.

If any references are passed, it uses C<Data::Dumper> to display the
references.

=head2 C<on_fail>

 use Test::Kit '+on_fail';

This exports an C<&on_fail> function into your namespace.  When called, if any
subsequent tests fail, it will execute the 'on_fail' subroutine passed in.

The function receives one argument, an object with the following methods:

=over 4

=item * C<name>

The 'name', if any, passed to the test function.  For example:

    ok $value, 'The value should be true';

The 'name' is "The value should be true".

=item * C<package>

The package the test function was called in.

=item * C<filename>

The name of the file the test function was called in.

=item * C<line>

The line number of the file the test function was called in.

=back

=cut

use Test::Builder;
use base 'Test::Builder::Module';

my %method_for = (
    explain => \&_setup_explain,
    on_fail => \&_on_fail,
);

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

sub _export {
    my ( $callpack, $name, $sub ) = @_;
    my $export = "$callpack\::$name";
    no strict 'refs';
    *$export = $sub;
}

sub _setup_explain {
    my ( $class, $callpack, @args ) = @_;

    my $explain = sub {
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
    _export( $callpack, 'explain', $explain );
    return @args;
}

{

    package Test::Kit::Result;

    sub new {
        my ( $class, $result, $package, $filename, $line ) = @_;
        bless {
            %$result,
            F_PACKAGE  => $package,
            F_FILENAME => $filename,
            F_LINE     => $line,
        } => $class;
    }
    sub actual_ok { shift->{actual_ok} }
    sub name      { shift->{name} }
    sub ok        { shift->{ok} }
    sub reason    { shift->{reason} }
    sub type      { shift->{type} }
    sub package   { shift->{F_PACKAGE} }
    sub filename  { shift->{F_FILENAME} }
    sub line      { shift->{F_LINE} }
}

sub _on_fail {
    my ( $class, $callpack, @args ) = @_;
    my $ok_func = \&Test::Builder::ok;

    no warnings 'redefine';

    my ( $PACKAGE, $FILENAME, $LINE );

    # we need this because if the failure is on the final test, we won't have
    # a subsequent test triggering the behavior.
    *Test::Builder::DESTROY = sub {
        my $builder = $_[0];
        if ( $builder->{TEST_KIT_test_failed} ) {
            $builder->{TEST_KIT_failure_action}->(
                Test::Kit::Result->new(
                    $builder->{Test_Results}[-1],
                    $PACKAGE, $FILENAME, $LINE,
                )
            );
        }
    };

    my $sub = sub (&) {
        my $action = shift;

        no warnings 'redefine';
        Test::Builder->new->{TEST_KIT_failure_action} = $action;   # for DESTROY

        *Test::Builder::ok = sub {
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            my $builder = $_[0];
            if ( $builder->{TEST_KIT_test_failed} ) {
                $builder->{TEST_KIT_test_failed} = 0;
                $action->(
                    Test::Kit::Result->new(
                        $builder->{Test_Results}[-1],
                        $PACKAGE, $FILENAME, $LINE,
                    )
                );
            }
            $builder->{TEST_KIT_test_failed} = 0;
            ( $PACKAGE, $FILENAME, $LINE ) = caller(1);
            my $result = $ok_func->(@_);
            if($builder->can('history')) {
                $builder->{TEST_KIT_test_failed} = $builder->history->last_result->is_fail;
            } else {
                $builder->{TEST_KIT_test_failed} = !( $builder->summary )[-1];
            }

            return $result;
        };
    };
    _export( $callpack, 'on_fail', $sub );
    return @args;
}

1;
