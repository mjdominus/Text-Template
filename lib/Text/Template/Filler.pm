package Text::Template::Filler;
use Text::Template::Util qw(_param _default_broken _gensym _install_hash
                            _scrubpkg
                          );
use strict;

sub new {
  my ($class, $template, %fi_a) = @_;
  my $self = {};

  $self->{varhash} = _param('hash', %fi_a);
  $self->{package} = _param('package', %fi_a) ;
  $self->{broken}  =
    _param('broken', %fi_a)
      || $template->{BROKEN}
      || \&Text::Template::Util::_default_broken;
  $self->{broken_arg} = _param('broken_arg', %fi_a) || [];
  $self->{safe} = _param('safe', %fi_a);
  $self->{ofh} = _param('output', %fi_a);
  $self->{filename} = _param('filename')
    || $template->{FILENAME}
    || 'template';

  $self->{prepend} = _param('prepend', %fi_a);

  bless $self => $class;
}

sub fill {
  my ($fi_filler, $fi_template) = @_;

  unless (defined $fi_filler->{prepend}) {
    $fi_filler->{prepend} = $fi_template->prepend_text;
  }

  my ($fi_eval_package, $fi_scrub_package);
  if (defined $fi_filler->{safe}) {
    $fi_eval_package = 'main';
  } elsif (defined $fi_filler->{package}) {
    $fi_eval_package = $fi_filler->{package};
  } elsif (defined $fi_filler->{varhash}) {
    $fi_eval_package = _gensym();
    $fi_scrub_package = 1;
  } else {
    $fi_eval_package = caller;
  }

  my $fi_install_package;
  if (defined $fi_filler->{varhash}) {
    if (defined $fi_filler->{package}) {
      $fi_install_package = $fi_filler->{package};
    } elsif (defined $fi_filler->{safe}) {
      $fi_install_package = $fi_filler->{safe}->root;
    } else {
      $fi_install_package = $fi_eval_package; # The gensymmed one
    }
    _install_hash($fi_filler->{varhash} => $fi_install_package);
  }

  if (defined $fi_filler->{package} && defined $fi_filler->{safe}) {
    no strict 'refs';
    # Big fat magic here: Fix it so that the user-specified package
    # is the default one available in the safe compartment.
    *{$fi_filler->{safe}->root . '::'} = \%{$fi_filler->{package} . '::'};   # LOD
  }

  my $fi_r = '';
  my $fi_item;
  foreach $fi_item (@{$fi_template->source}) {
    my ($fi_type, $fi_text, $fi_lineno) = @$fi_item;
    if ($fi_type eq 'TEXT') {
      $fi_template->append_text_to_output(
        text   => $fi_text,
        handle => $fi_filler->{ofh},
        out    => \$fi_r,
        type   => $fi_type,
      );
    } elsif ($fi_type eq 'PROG') {
      no strict;
      my $fi_lcomment = "#line $fi_lineno $fi_filler->{filename}";
      my $fi_progtext =
        "package $fi_eval_package; $fi_filler->{prepend};\n$fi_lcomment\n$fi_text;";
      my $fi_res;
      my $fi_eval_err = '';
      if ($fi_filler->{safe}) {
        $fi_filler->{safe}->reval(q{undef $OUT});
	$fi_res = $fi_filler->{safe}->reval($fi_progtext);
	$fi_eval_err = $@;
	my $OUT = $fi_filler->{safe}->reval('$OUT');
	$fi_res = $OUT if defined $OUT;
      } else {
	my $OUT;
	$fi_res = eval $fi_progtext;
	$fi_eval_err = $@;
	$fi_res = $OUT if defined $OUT;
      }

      # If the value of the filled-in text really was undef,
      # change it to an explicit empty string to avoid undefined
      # value warnings later.
      $fi_res = '' unless defined $fi_res;

      if ($fi_eval_err) {
	$fi_res = $fi_filler->{broken}->
	  (text => $fi_text,
	   error => $fi_eval_err,
	   lineno => $fi_lineno,
	   arg => $fi_filler->{broken_arg},
	  );
	if (defined $fi_res) {
          $fi_template->append_text_to_output(
            text   => $fi_res,
            handle => $fi_filler->{ofh},
            out    => \$fi_r,
            type   => $fi_type,
          );
	} else {
	  return $fi_res;		# Undefined means abort processing
	}
      } else {
        $fi_template->append_text_to_output(
          text   => $fi_res,
          handle => $fi_filler->{ofh},
          out    => \$fi_r,
          type   => $fi_type,
        );
      }
    } else {
      die "Can't happen error #2";
    }
  }

  _scrubpkg($fi_eval_package) if $fi_scrub_package;
  defined $fi_filler->{ofh} ? 1 : $fi_r;
}

1;
