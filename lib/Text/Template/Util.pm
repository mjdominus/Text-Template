package Text::Template::Util;
use base 'Exporter';
our @EXPORT_OK = qw(_is_clean _unconditionally_untaint _load_class
                    _param _load_text);

sub _is_clean {
  my $z;
  eval { ($z = join('', @_)), eval '#' . substr($z,0,0); 1 }   # LOD
}

sub _unconditionally_untaint {
  for (@_) {
    ($_) = /(.*)/s;
  }
}

sub _load_class {
  my ($class) = @_;
  $class =~ s{::}{/}g;
  require "$class.pm";
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

sub _param {
  my $kk;
  my ($k, %h) = @_;
  for $kk ($k, "\u$k", "\U$k", "-$k", "-\u$k", "-\U$k") {
    return $h{$kk} if exists $h{$kk};
  }
  return;
}

1;
