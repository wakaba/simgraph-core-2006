package SimGraph::Sim;
use strict;

sub new ($;$) {
  my ($class, $param) = @_;
  my $self = bless {}, $class;
  
  if (ref $param) {
    $self->{param} = $param;
  } else {
    $self->_set_default_param;
  }
  
  return $self;
} # new

sub _set_default_param ($) {
  die "$0: new: No parameter set is specified";
} # _set_default_param

sub param ($;$) {
  my $self = shift;
  $self->{param} = shift if @_;
  return $self->{param};
} # param

sub file_name_stem ($) {
  my $self = shift;
  return $self->{param}->file_name_stem;
} # file_name_stem

sub file_name ($;%) {
  my $self = shift;
  return $self->{param}->file_name (@_);
} # file_name

sub command ($$) {
  my ($self, $cmd) = @_;
  die "$0: command: Command $cmd is not supported";
} # command

1;
# $Date: 2007/03/09 12:25:49 $
