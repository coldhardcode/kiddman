package Kiddman;

use strict;
use warnings;

use Catalyst::Runtime '5.70';
use parent qw/Catalyst/;

our $VERSION = '0.01';

=head1 NAME

Kiddman - Meta-Content Management System

=head1 SYNOPSIS

    script/kiddman_server.pl

=head1 DESCRIPTION

[enter your description here]

=cut

# Configure the application. 
#
# Note that settings in kiddman.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'kiddman' );

# Start the application
__PACKAGE__->setup(qw/
    -Debug
    Authentication
    Authorization::Roles
    ConfigLoader
    FormValidator
    I18N
    Params::Nested
    Static::Simple
/);

=head1 ACTIONS

=head2 action_uri

Convenience method for linking to chained actions.

=cut
sub action_uri {
    my ($c, $controller, $action, @params) = @_;
    return $c->uri_for($c->controller($controller)->action_for($action), @params);
}

=head2 form_is_valid

Convenience method validating forms.

=cut
sub form_is_valid {
    my ($self) = @_;

    if($self->form->has_invalid || $self->form->has_missing) {
        return 0;
    }

    return 1;
}

=head2 get_provider

Checks Kiddman's configuration options for a type provider for the given
type.  Returns an instance of the type provider if one exists, else undef.

=cut
sub get_provider {
    my ($self, $type) = @_;

    if(defined($self->config->{TypeProvider}) && defined($self->config->{TypeProvider}->{$type})) {
        my $provider = undef;
        eval {
            my $provname = $self->config->{TypeProvider}->{$type};
            Class::MOP::load_class($provname);
            $provider = $provname->new;
        };
        if($@) {
            print STDERR "$@";
            $self->log->error("Failed to load type provider for '$type': $@");
        }

        return $provider;
    }

    return undef;
}

=back

=head1 SEE ALSO

L<Kiddman::Controller::Root>, L<Catalyst>, L<Kiddman::Client>

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
