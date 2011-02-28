package SimGraph::Sim::Object;
use strict;

sub new ($$) {
  my ($class, $env) = @_;
  my $self = bless {
    env => $env,
  }, $class;
  return $self;
} # new

sub env ($) {
  return shift->{env};
} # env

sub id ($;$) {
  my $self = shift;
  if (@_) {
    $self->{id} = shift;
  }
  return $self->{id};
} # id

1;
# $Date: 2007/04/17 07:00:10 $
