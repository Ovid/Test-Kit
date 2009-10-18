package Test::Kit;

use warnings;
use strict;
use Carp ();
use namespace::clean;

use Test::Kit::Features;

=head1 NAME

Test::Kit - Build custom test packages with only the features you want.

=head1 VERSION

Version 0.100

=cut

our $VERSION = '0.100';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

    package My::Custom::Tests;

    use Test::Kit
        'Test::More',
        'Test::XML',
        'Test::Differences',
        '+explain',
    );

=head1 DESCRIPTION

Build custom test modules, using other test modules for parts.

=over 4

=item * C<kit>:

    A set of materials or parts from which something can be assembled.

=back

How many times have you opened up a test program in a large test suite and
seen 5 or 6 C<use Test::...> lines?  And then you open up a bunch of other
test programs and they all have the same 5 or 6 lines.  That's duplication you
don't want.  C<Test::Kit> allows you to I<safely> push that code into one
custom test package and merely use that package.  It does this by treating
various test module's functions as pieces you can assemble together.

Also, you can import 'features' to extend your testing possibilities.

=head1 USAGE

=head2 Basic

Create a package for your tests and add the test modules you want.

     package My::Tests;

     use Test::Kit qw(
         Test::Differences
         Test::Exception
     );

Then in your test programs, all exported test functions from those modules
will be available.  C<Test::More> functions are included by default.  If you
add 'Test::Most' to your C<Test::Kit> import list, it will take precedence
over C<Test::More>.

    use My::Tests plan => 3;

    is 3, 3, 'this if from Test::More';
    eq_or_diff [ 3, 3 ], [ 3, 3 ], 'this is from Test::Differences';
    throws_ok { die 'test message' }
        qr/^test message/,
        '... and this is from Test::Exception';

=head2 Using "Features"

Additional features, as detailed in L<Test::Kit::Features>, are available.
Two common features are 'explain' and 'on_fail'.  To use a feature, just add a
'+' (plus) before the feature name:

     package My::Tests;

     use Test::Kit qw(
         Test::Differences
         Test::Exception
         Test::XML
         Test::JSON
         +explain
         +on_fail
     );

=head2 Advanced usage

Sometimes two or more test modules may try to export a function with the same
name.  This will cause a compile time failure listing which modules export
which conflicting function.  There are two ways of dealing with this: renaming
and excluding.  To do this, add a hashref after the module name with keys
'exclude', 'rename', or both.

    use Test::Most 
        'Test::Something' => {
            # or a scalar for just one
            exclude => [qw/ list of excluded functions/],
        },
        'Test::Something::Else' => {
            # takes a hashref
            rename => {
                old_test_function_name => 'new_test_function_name',
            },
        },
        '+explain';

=cut

my %FUNCTION;

sub import {
    my $class    = shift;
    my $callpack = caller(1);

    my $basic_functions = namespace::clean->get_functions($class);

    # not implementing features yet
    my ( $packages, $features ) = $class->_packages_and_features(@_);
    $class->_setup_import($features);

    foreach my $package ( keys %$packages ) {
        my $internal_package = "Test::Kit::_INTERNAL_::$package";
        eval "package $internal_package; use $package;";
        if ( my $error = $@ ) {
            Carp::croak("Cannot require $package:  $error");
        }

        $class->_register_new_functions( $callpack, $basic_functions,
            $packages->{$package}, $package, $internal_package, );
    }
    $class->_validate_functions($callpack);
    $class->_export_to($callpack);

    {

        # Otherwise, "local $TODO" won't work for caller.
        no strict 'refs';
        our $TODO;
        *{"$callpack\::TODO"} = \$TODO;
    }
    return 1;
}

sub _setup_import {
    my ( $class, $features ) = @_;
    my $callpack = caller(1);              # this is the composed test package
    my $import   = "$callpack\::import";
    my $isa      = "$callpack\::ISA";
    no strict 'refs';
    if ( defined &$import ) {
        Carp::croak("Class $callpack must not define an &import method");
    }
    else {
        unshift @$isa => 'Test::Kit::Features';
        *$import = sub {
            my ( $class, @args ) = @_;
            @args = $class->BUILD(@args) if $class->can('BUILD');
            @args = $class->_setup_features( $features, @args );
            @_ = ( $class, @args );
            goto &Test::Builder::Module::import;
        };
    }
}

sub _reset {    # internal testing hook
    %FUNCTION = ();
}

sub _validate_functions {
    my ( $class, $callpack ) = @_;
    my @errors;
    while ( my ( $function, $definition ) = each %{ $FUNCTION{$callpack} } ) {
        my @source = @{ $definition->{source} };
        if ( @source > 1 ) {
            my $sources = join ', ' => sort @source;
            push @errors =>
"Function &$function exported from more than one package:  $sources";
        }
    }
    Carp::croak( join "\n" => @errors ) if @errors;
}

# XXX ouch.  This is really getting crufty
sub _register_new_functions {
    my ( $class, $callpack, $basic_functions, $definition, $source, $package ) =
      @_;
    my $new_functions = namespace::clean->get_functions($package);
    $new_functions =
      $class->_remove_basic_functions( $basic_functions, $new_functions, );

    my $exclude = delete $definition->{exclude};
    $exclude = [$exclude] unless 'ARRAY' eq ref $exclude;

    my $rename = delete $definition->{rename} || {};

    if ( my @keys = keys %$definition ) {
        my $keys = join ', ' => sort @keys;
        Carp::croak("Uknown keys in module definition: $keys");
    }

    # turn it into a hash lookup
    no warnings 'uninitialized';
    $exclude = { map { $_ => 1 } @$exclude };
    foreach my $function ( keys %$new_functions ) {
        next if $exclude->{$function};
        my $glob = $new_functions->{$function};
        if ( my $new_name = $rename->{$function} ) {
            $function = $new_name;
        }
        $FUNCTION{$callpack}{$function}{glob} = $glob;
        $FUNCTION{$callpack}{$function}{source} ||= [];
        push @{ $FUNCTION{$callpack}{$function}{source} } => $source;
    }
}

sub _packages_and_features {
    my ( $class, @requests ) = @_;
    my ( %packages, @features );
    while ( my $package = shift @requests ) {
        if ( $package =~ s/\A\+// ) {

            # it's a feature, not a package
            push @features => $package;
            next;
        }
        my $definition = 'HASH' eq ref $requests[0] ? shift @requests : {};
        $packages{$package} = $definition;
    }

    # Don't include Test::More because Test::Most will automatically provide
    # these features
    $packages{'Test::More'} ||= {}
      unless exists $packages{'Test::Most'};
    return ( \%packages, \@features );
}

sub _remove_basic_functions {
    my ( $class, $basic, $new ) = @_;
    delete @{$new}{ keys %$basic };
    return $new;
}

sub _export_to {
    my ( $class, $target ) = @_;

    while ( my ( $function, $definition ) = each %{ $FUNCTION{$target} } ) {
        my $target_function = "$target\::$function";
        no strict 'refs';
        *$target_function = $definition->{glob};
    }
    return 1;
}

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-kit at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Kit>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Kit

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Kit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Kit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Kit>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Kit>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Test::Kit
