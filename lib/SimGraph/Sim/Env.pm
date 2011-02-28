package SimGraph::Sim::Env;
use strict;

sub new ($) {
  my $class = shift;
  my $self = bless {
    current_time => 0,
    events => [],
    event_id => 0,
    end_time => 10_000_000,
  }, $class;
  return $self;
} # new

sub next_id ($$) {
  my ($self, $ns) = @_;
  return (0 + $self->{next_id}->{$ns}++);
} # next_id

sub param ($$;$) {
  my $self = shift;
  my $param_name = shift;
  if (@_) {
    $self->{param}->{$param_name} = shift;
  }
  return $self->{param}->{$param_name};
} # param

=item I<$event_id> = I<$env>->schedule (I<$delta_time>, I<$code>)

@@ ...

The method returns an opaque number, I<$event_id>, which
is a unique identifier for the scheduled event.  It is later used
to cancel the event.

=cut

sub schedule ($$$;$) {
  ## NOTE: The third parameter ($_[3]) is only for internal use.
  my ($self, $delta_time, $code, $event_id) = @_;
  my $time = $self->{current_time} + int $delta_time;
  $event_id = ++$self->{event_id} unless defined $event_id;
  my $event = {exec_time => $time, code => $code, id => $event_id};
  for my $i (0..$#{$self->{events}}) {
    if ($self->{events}->[$i]->{exec_time} > $time) {
      splice @{$self->{events}}, $i, 0, ($event);
      return $event_id;
    }
  }
  push @{$self->{events}}, ($event);
  return $event_id;
} # schedule

sub schedule_interval ($$$;$) {
  ## NOTE: The third parameter ($_[3]) is only for internal use.
  my ($self, $interval, $code, $event_id) = @_;
  $event_id = ++$self->{event_id} unless defined $event_id;
  return $self->schedule ($interval, sub {
    my $self = shift;
    $code->($self);
    $self->schedule_interval ($interval, $code, $event_id);
  }, $event_id);
} # schedule_interval

=item I<$env>->cancel_event (I<$event_id>)

Cancels the execution of the event.

Parameters:

=over 4

=item I<$event_id> (REQUIRED)

The identifier of the event, which is returned when the event
is registered by the I<schedule> method.  This parameter MUST
be specified.  If it does not specify any event registered,
or it does specify ongoing or past event, then this method 
has no effect.

=back

=cut

sub cancel_event ($$) {
  my ($self, $id) = @_;
  for (0..$#{$self->{events}}) {
    if ($self->{events}->[$_]->{id} == $id) {
      splice @{$self->{events}}, $_, 1, ();
      return;
    }
  }
} # cancel_event

sub execute ($) {
  my $self = shift;
  while (@{$self->{events}}) {
    my $event = shift @{$self->{events}};
    last if $event->{exec_time} > $self->{end_time};
    $self->current_time ($event->{exec_time});
    $event->{code}->($self);
  }
} # execute

for (qw/current_time end_time result/) {
  eval q[
    sub ] . $_ . q[ ($;$) {
      my $self = shift;
      if (@_) {
        $self->{] . $_ . q[} = shift;
      }
      return $self->{] . $_ . q[};
    }
  ];
}

1;
# $Date: 2007/06/06 05:58:56 $
