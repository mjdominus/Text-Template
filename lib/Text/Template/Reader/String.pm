package Text::Template::Reader::String;
use strict;
use Text::Template::Reader::Base;
our @ISA = qw(Text::Template::Reader::Base);

sub load_template_data { return $_[0]{source} }

1;
