package Text::Template::Reader::Array;
use strict;
use Text::Template::Reader::Base;
our @ISA = qw(Text::Template::Reader::Base);

sub load_template_data {
    my ($self) = @_;
    return join "", @{$self->source};
}

# We have to override this because Perl's taint check will report that
# the source array is untainted even if it contains unsafe strings.
sub source_is_safe { 0 }

1;
