package Text::Template::Reader::Base;
use Carp qw(croak);
use strict;

sub new {
    my ($class, $source) = @_;
    if ($class eq __PACKAGE__) {
	croak "Cannot instantiate abstract class '$class'";
    }
    bless { source => $source } => $class;
}

sub source { $_[0]{source} }

sub source_is_safe {
    my ($self) = @_;
    Text::Template::_is_clean($self->source);
}

1;
