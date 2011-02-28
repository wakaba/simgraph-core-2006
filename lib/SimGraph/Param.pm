package SimGraph::Param;
use strict;

sub new ($;%) {
  my $class = shift;
  my $self = bless {}, $class;
  
  while (my ($k, $v) = splice @_, 0, 2) {
    $self->$k ($v);
  }
  
  return $self;
} # new

sub argument_list ($$) {
  my ($self, $target) = @_;
  my @r;
  $target = {arcp3sim => 'arcp2sim', rpdrivensim => 'arcp2sim'}->{$target} || $target;
  
  my $param = $self->_param;
  
  for my $internal_param_name (sort {$a cmp $b} keys %$param) {
    my $param_def = $param->{$internal_param_name};
    next unless defined $param_def->{name}->{$target};
    my $param_name = $param_def->{name}->{$target};
    my $value = $self->{$internal_param_name};
    $value = $param_def->{default} unless defined $value;
    if ($param_def->{convert}->{$target}) {
      $value = $param_def->{convert}->{$target}->($value);
    }
    my $value_type = $param_def->{type};
    if ($value_type eq 'boolean') {
      $value = $value ? 1 : 0;
    } elsif ($value_type eq 'real') {
      $value += 0;
    } elsif ($value_type eq 'integer') {
      $value = int $value;
    } elsif ($value_type eq 'integer-set') {
      push @r, $param_name => $_ for @$value;
      next;
    } else {
      $value .= '';
    }
    push @r, $param_name => $value;
  }
  
  return @r;
} # argument_list

sub directory_name ($;$) {
  my $self = shift;
  $self->{directory_name} = shift if @_;
  return defined $self->{directory_name} ? $self->{directory_name} : 'I/';
} # directory_name

sub file_name_stem ($) {
  die "$0: file_name_stem: Not implemented";
} # file_name_stem

sub file_name ($;%) {
  die "$0: file_name: Not implemented";
} # file_name

sub file_name_pattern ($;%) {
  die "$0: file_name_pattern: Not implemented";
} # file_name_pattern

sub file_name_prefix ($;$) {
  my $self = shift;
  $self->{file_name_prefix} = shift if @_;
  return defined $self->{file_name_prefix} ? $self->{file_name_prefix} : 'I';
} # file_name_prefix

sub latex_short_description ($) {
  my $self = shift;
  my $param = $self->_param;
  my @r;
  
  for my $internal_param_name (sort {$a cmp $b} keys %$param) {
    my $name = $param->{$internal_param_name}->{name}->{latex};
    next unless defined $name;
    
    my $value_attr = "non_default_$internal_param_name";
    if ($param->{$internal_param_name}->{type} eq 'integer-set') {
      my @value = $self->$internal_param_name;
      push @r, "$name = " . join ',', @value;
    } else {
      my $value = $self->$value_attr;
      next unless defined $value;
      
      push @r, "$name = $value";
    }
  }
  
  return join ', ', @r;
} # latex_short_description

sub AUTOLOAD {
  our $AUTOLOAD;
  $AUTOLOAD =~ s/.*:://;
  
  my $flag = '';
  $flag = 'non_default' if $AUTOLOAD =~ s/^non_default_//;
  
  my $self = shift;
  my $param = $self->_param;
  if ($param->{$AUTOLOAD}) {
    if (@_) {
      my $v = shift;
      if (defined $v) {
        $self->{$AUTOLOAD} = $v;
      } else {
        delete $self->{$AUTOLOAD};
      }
    }
    my $value = defined $self->{$AUTOLOAD} ? $self->{$AUTOLOAD} : $param->{$AUTOLOAD}->{default};
    if ($flag eq 'non_default') {
      if ({
        boolean => 1,
        integer => 1,
        real => 1,
      }->{$param->{$AUTOLOAD}->{type}}) {
        $value = undef if $param->{$AUTOLOAD}->{default} == $value;
      } elsif ($param->{$AUTOLOAD}->{type} eq 'integer-set') {
        #
      } else {
        $value = undef if $param->{$AUTOLOAD}->{default} eq $value;
      }
    }
    return $value;
  } else {
    die "$0: " . ref ($self) . ": Attribute $AUTOLOAD not found";
  }
} # AUTOLOAD

sub DESTROY {

} # DESTROY

sub _param () {
  return {};
} # _param

sub c_getopt ($$) {
  my ($self, $target) = @_;
  my $param = $self->_param;
  
  my @arg;
  
  my @key = ('0'..'9', 'A'..'Z', 'a'..'z');
  for (sort {$a cmp $b} keys %$param) {
    my $param_def = $param->{$_};
    
    my $param_name = $param_def->{name}->{$target};
    next unless defined $param_name;
    $param_name =~ s/^--//;
    
    my $code = $param_def->{c}->{$target};
    $code = qq[ fe_die ("--%s: Unimplemented argument", "$param_name"); ]
        unless defined $code;
    
    my $key = shift @key;
    die "$0: Too many argument defined for $target" unless defined $key;
    
    push @arg, [$param_name, $key, $code];
  }
  
  my $r = q[
    #include <stdlib.h>
    #include <getopt.h>
  ];
  
  $r .= $self->_c_getopt_header;
  
  $r .= q[
    void sgparam_read_arguments (int argc, char * const argv[]) {
      while (1) {
        int c;
        int option_index = 0;
        static struct option long_options[] = {
  ];
  
  for (@arg) {
    $r .= qq[ {"$_->[0]", required_argument, 0, '$_->[1]'}, \n];
  }
  
  $r .= q[
        {0, 0, 0, 0}
      };
      
      c = getopt_long (argc, argv, "aces", long_options, &option_index);
      if (c == -1) break;
      
      switch (c) {
  ];
  
  for (@arg) {
    $r .= qq[
      case '$_->[1]': /* --$_->[0] */
        $_->[2]
        break;
    ];
  }

  $r .= q[
      default:
        fe_die ("getopt_long return code: %d\n", c);
      }
    } /* arguments */

    if (optind < argc) {
      fe_die ("Unknown argument: %s\n", argv[optind]);
    }
  ];
  
  $r .= $self->_c_getopt_check;
  
  $r .= q[
    } /* sgparam_read_arguments */
    
    /* sgparam.c ends here */
  ];
  $r .= qq[\n]; ## Avoid no newline at end of file warning
  
  return $r;
} # c_getopt

sub _c_getopt_check () {
  return '';
} # _c_getopt_check

sub _c_getopt_header () {
  return q[
    #include "error.h"
  ];
} # _c_getopt_header

sub perl_getopt_long ($$) {
  my ($self, $target) = @_;
  my $param = $self->_param;
  
  my $package = ref $self;
  my $r = '
    use strict;
    use Pod::Usage;
    use Getopt::Long;
    use '.$package.';
    our $Param = '.$package.'->new;
    my %has_required;
    GetOptions (
      help => sub { pod2usage 1 },
  ';
  
  my @required;
  
  for my $internal_name (sort {$a cmp $b} keys %$param) {
    my $param_def = $param->{$internal_name};
    
    my $param_name = $param_def->{name}->{$target};
    next unless defined $param_name;
    $param_name =~ s/^--//;
    
    $r .= q<'> . $param_name;
    if ({
      integer => 1, real => 1, string => 1, boolean => 1, 'integer-set' => 1,
    }->{$param_def->{type}}) {
      $r .= q<=s>;
    } else {
      die "$0: $target: --$param_name: Parameter type |$param_def->{type}| is not supported";
    }
    if ($param_def->{type} eq 'integer-set') {
      $r .= qq[' => sub {
        shift;
        push \@{\$Param->{$internal_name} ||= []}, shift;
      ];
    } else {
      $r .= qq[' => sub {
        shift;
        \$Param->$internal_name (shift);
      ];
    }
    if ($param_def->{required}->{$target}) {
      $r .= '$has_required{q<' . $param_name . '>} = 1;';
      push @required, $param_name;
    }
    $r .= qq[},\n];
  }
  
  $r .= '
    ) or pod2usage 2;
  ';
  if (@required) {
    $r .= 'if (';
    $r .= join ' or ', map { 'not $has_required{q<' . $_ . '>}' } @required;
    $r .= ") {
      for (qw/@required/) {
        warn qq<Missing option: \$_\n> unless \$has_required{\$_};
      }
      pod2usage 2;
    }";
  }
  $r .= "1;\n";
  return $r;
} # perl_getopt_long

use Storable qw/dclone/;

sub clone ($) {
  my ($self) = @_;
  return dclone ($self);
} # clone

sub job ($) {
  my ($self) = @_;
  return $self;
} # job

1;
# $Date: 2007/08/21 07:15:19 $
