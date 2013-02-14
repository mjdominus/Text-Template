package Text::Template::Reader::Filehandle;
use strict;
use Text::Template::Reader::Base;
our @ISA = qw(Text::Template::Reader::Base);

sub load_template_data {
    my ($self) = @_;
    my $fh = $self->source;
    local $/;
    return <$fh>;
}

1;
