package SimGraph::Sim::Main;
use strict;
require SimGraph::Sim::Env;

sub new ($) {
  my ($class) = @_;
  my $self = bless {
    env => scalar SimGraph::Sim::Env->new,
  }, $class;
  return $self;
} # new

sub env ($) {
  return shift->{env};
} # env

sub start ($) {
  my $self = shift;
  $self->init;
  $self->execute;
  $self->terminate;
} # start

sub init ($) { }

sub execute ($) {
  die "|execute|: Not defined";
} # execution

sub terminate ($) { }

1;
# $Date: 2007/05/25 04:39:24 $
