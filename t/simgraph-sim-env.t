#!/usr/bin/perl
use strict;

use Test;
BEGIN { plan tests => 15 }
use SimGraph::Sim::Main;

package test::sim;
push our @ISA, 'SimGraph::Sim::Main';

sub execute {
  shift->env->execute;
}

package main;

my $sim = test::sim->new;

my $env = $sim->env;
$env->end_time (10_000);

my @expected_event_time;
my @actual_event_time;

$expected_event_time[0] = 1000;
$env->schedule (1000, sub {
  $actual_event_time[0] = $env->current_time;
});

$expected_event_time[1] = 2000;
$env->schedule (2000, sub {
  $actual_event_time[1] = $env->current_time;
});
$expected_event_time[2] = 2000;
$env->schedule (2000, sub {
  $actual_event_time[2] = $env->current_time;
});

$expected_event_time[3] = 3000;
$expected_event_time[4] = 6000;
$expected_event_time[5] = 9000;
$expected_event_time[6] = undef; # since end_time == 10_000
my $i = 0;
$env->schedule_interval (3000, sub {
  $actual_event_time[3 + $i++] = $env->current_time;
});

$expected_event_time[7] = undef;
my $id = $env->schedule (5000, sub {
  $actual_event_time[7] = $env->current_time;
});
$env->cancel_event ($id);

$expected_event_time[8] = 10_000;
$env->schedule (10_000, sub {
  $actual_event_time[8] = $env->current_time;
});

$expected_event_time[9] = undef; # since end_time == 10_000
$env->schedule (10_001, sub {
  $actual_event_time[9] = $env->current_time;
});

$expected_event_time[10] = 0;
$env->schedule (0, sub {
  $actual_event_time[10] = $env->current_time;
});

$expected_event_time[11] = 100;
$expected_event_time[12] = 200;
$expected_event_time[13] = 300;
$expected_event_time[14] = undef;
my $j = 0;
my $id2 = $env->schedule_interval (100, sub {
  $actual_event_time[11 + $j++] = $env->current_time;
});
$env->schedule (350, sub {
  $env->cancel_event ($id2);
});

$sim->execute;

ok $actual_event_time[$_], $expected_event_time[$_] for 0..$#expected_event_time;
