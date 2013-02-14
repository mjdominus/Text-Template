package Text::Template::Reader::File;
use strict;
use Text::Template::Reader::Base;
use Try::Tiny;
our @ISA = qw(Text::Template::Reader::Base);

sub load_template_data {
    my ($self) = @_;
    my $text;
    try { $text = _load_text($self->source) }
    catch { $Text::Template::ERROR = $_; return };
    return $text;
}

sub _load_text {
    my $fn = shift;
    local *F;
    unless (open F, $fn) {
	die "Couldn't open file $fn: $!";
    }
    local $/;
    <F>;
}

1;
