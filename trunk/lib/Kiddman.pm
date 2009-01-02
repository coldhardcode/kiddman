package Kiddman;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use parent qw/Catalyst/;

our $VERSION = '0.01';

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

=item action_uri

Convenience method for linking to chained actions

=cut
sub action_uri {
    my ($c, $controller, $action, @params) = @_;
    return $c->uri_for($c->controller($controller)->action_for($action), @params);
}

=item form_is_valid

=cut
sub form_is_valid {
	my ($self) = @_;

	if($self->form->has_invalid || $self->form->has_missing) {
		return 0;
	}

	return 1;
}

=head1 NAME

kiddman - Catalyst based application

=head1 SYNOPSIS

    script/kiddman_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Kiddman::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Cory Watson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
