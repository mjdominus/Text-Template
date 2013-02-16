package Text::Template::Compiler;

sub new {
  my ($class, %args) = @_;
  my $delim = Text::Template::_param('delimiters', %args);
  my @delim =  $delim && @$delim
    ? (DELIMITERS => $delim) : ();
  bless { @delim } => $class;
}

sub delimiters {
  my ($self) = @_;
  $self->{DELIMITERS};
}

sub compile {
  my ($self, $template, $args) = @_;

  return undef unless $template->_acquire_data;

  my @tokens;
  my $delim = Text::Template::_param('delimiters', %$args);
  my $delim_pats = $delim || $self->delimiters;

  my ($t_open, $t_close) = ('{', '}');
  my $DELIM;			# Regex matches a delimiter if $delim_pats
  if (defined $delim_pats) {
    ($t_open, $t_close) = @$delim_pats;
    $DELIM = "(?:(?:\Q$t_open\E)|(?:\Q$t_close\E))";
    @tokens = split /($DELIM|\n)/, $template->{DATA};
  } else {
    @tokens = split /(\\\\(?=\\*[{}])|\\[{}]|[{}\n])/, $template->{DATA};
  }
  my $state = 'TEXT';
  my $depth = 0;
  my $lineno = 1;
  my @content;
  my $cur_item = '';
  my $prog_start;
  while (@tokens) {
    my $t = shift @tokens;
    next if $t eq '';
    if ($t eq $t_open) {	# Brace or other opening delimiter
      if ($depth == 0) {
	push @content, [$state, $cur_item, $lineno] if $cur_item ne '';
	$cur_item = '';
	$state = 'PROG';
	$prog_start = $lineno;
      } else {
	$cur_item .= $t;
      }
      $depth++;
    } elsif ($t eq $t_close) {	# Brace or other closing delimiter
      $depth--;
      if ($depth < 0) {
	$ERROR = "Unmatched close brace at line $lineno";
	return undef;
      } elsif ($depth == 0) {
	push @content, [$state, $cur_item, $prog_start] if $cur_item ne '';
	$state = 'TEXT';
	$cur_item = '';
      } else {
	$cur_item .= $t;
      }
    } elsif (!$delim_pats && $t eq '\\\\') { # precedes \\\..\\\{ or \\\..\\\}
      $cur_item .= '\\';
    } elsif (!$delim_pats && $t =~ /^\\([{}])$/) { # Escaped (literal) brace?
	$cur_item .= $1;
    } elsif ($t eq "\n") {	# Newline
      $lineno++;
      $cur_item .= $t;
    } else {			# Anything else
      $cur_item .= $t;
    }
  }

  if ($state eq 'PROG') {
    $ERROR = "End of data inside program text that began at line $prog_start";
    return undef;
  } elsif ($state eq 'TEXT') {
    push @content, [$state, $cur_item, $lineno] if $cur_item ne '';
  } else {
    die "Can't happen error #1";
  }

  $template->{IS_COMPILED} = 1;
  $template->{SOURCE} = \@content;
  return 1;
}

1;
