package Kiddman::Directory;
use Moose;

use overload '""' => sub { $_[0]->name.'/' };

has 'name' => (
    'is'        => 'rw',
    'isa'       => 'Str',
    'required'  => 1
);

=head2 is_leaf

Provided to make working with the L<Site|Kiddman::Site>'s C<get_entry_arrayref>
easier, as nodes can be tested for leaf status.  Returns false.

=cut
sub is_leaf {
	return 0;
}

1;