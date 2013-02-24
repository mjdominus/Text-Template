package Text::Template::Util;
use base 'Exporter';
our @EXPORT_OK = qw(_is_clean _unconditionally_untaint _load_class
                    _param _load_text _default_broken _gensym _scrubpkg
                    _install_hash
                  );

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

sub _default_broken {
  my %a = @_;
  my $prog_text = $a{text};
  my $err = $a{error};
  my $lineno = $a{lineno};
  chomp $err;
#  $err =~ s/\s+at .*//s;
  "Program fragment delivered error ``$err''";
}

{
  my $seqno = 0;
  sub _gensym {
    __PACKAGE__ . '::GEN' . $seqno++;
  }
  sub _scrubpkg {
    my $s = shift;
    $s =~ s/^Text::Template:://;
    no strict 'refs';
    my $hash = $Text::Template::{$s."::"};
    foreach my $key (keys %$hash) {
      undef $hash->{$key};
    }
  }
}

# Given a hashful of variables (or a list of such hashes)
# install the variables into the specified package,
# overwriting whatever variables were there before.
sub _install_hash {
  my $hashlist = shift;
  my $dest = shift;
  if (UNIVERSAL::isa($hashlist, 'HASH')) {
    $hashlist = [$hashlist];
  }
  my $hash;
  foreach $hash (@$hashlist) {
    my $name;
    foreach $name (keys %$hash) {
      my $val = $hash->{$name};
      no strict 'refs';
      local *SYM = *{"$ {dest}::$name"};
      if (! defined $val) {
	delete ${"$ {dest}::"}{$name};
      } elsif (ref $val) {
	*SYM = $val;
      } else {
	*SYM = \$val;
      }
    }
  }
}

1;
