package Text::Template::Reader;
use Carp;
use strict;
use Try::Tiny;

# Maps TYPE argument to the class that can read that source type
my %reader_class = (
    STRING     => "Text::Template::Reader::String",
    FILE       => "Text::Template::Reader::File",
    FILEHANDLE => "Text::Template::Reader::Filehandle",
    ARRAY      => "Text::Template::Reader::Array",
);

sub new {
    my ($class, %args) = @_;
    my $type = $args{type}
      or croak("Missing TYPE parameter");

    my $reader_class = $class->get_reader_class($type)
	or croak "Illegal value `$type' for TYPE parameter";

    unless (defined $args{source}) {
      require Carp;
      croak("Usage: new(TYPE => ..., SOURCE => ...)");
    }

    _load_class($reader_class);
    my $reader = $reader_class->new($args{source}) or return;
    bless { reader => $reader } => $class;
}

sub reader { $_[0]{reader} }
sub source_is_safe { $_[0]->reader->source_is_safe }

sub get_reader_class {
    my ($self, $source_type) = @_;
    return $reader_class{$source_type};
}

sub _load_class {
  my ($class) = @_;
  $class =~ s{::}{/}g;
  require "$class.pm";
}

sub load_template_data {
    my ($self) = @_;
    my $data;
    try { $data = $self->reader->load_template_data }
    catch {
      $Text::Template::ERROR = $_;
      return;
    };
    return $data;
}

1;
