#!/usr/bin/perl
use strict;
require 'params.pl';

my $JOB_DIRECTORY_NAME = './job/';

use Getopt::Long;
use Pod::Usage;
GetOptions (
    'help' => sub { pod2usage 1 },
    'job-directory-name=s' => \$JOB_DIRECTORY_NAME,
) or pod2usage 2;

use SimGraph::IO qw/xsystem/;
use Data::Dumper;

sub msg (@) { print STDERR '[', scalar localtime, '] ', @_, "\n" }

msg qq<Job directory: $JOB_DIRECTORY_NAME>;

use SimGraph::Scheduler;
use SimGraph::Param::ARCPSim;

my $sc = SimGraph::Scheduler->new (directory_name => $JOB_DIRECTORY_NAME);

our @SimSeed;
our %SimParam;

$SimGraph::Scheduler::OnError = sub ($) {
  warn @_;
  sleep 10;
  msg q<Restarting...>;
  exec $0;
};

my $no_job_msg = 1;
SLEEP: while (1) {

while (defined (my ($job, $num) = $sc->start_first_job)) {
  last unless defined $job;

    my $has_error;
    $SimGraph::IO::OnError = sub ($) {
      my $msg = shift;
      warn $msg;
      $sc->error_job ($num);
      $has_error = 1;
      die; # throw
    };

  msg qq<Starting job #$num...>;

  my $mode = $job->output_type;
  if ($mode eq 'job_stop') {
    msg q<Stopped>;
    $sc->remove_job ($num);
    last SLEEP;
  } elsif ($mode eq 'job_restart') {
    msg q<Restarting...>;
    $sc->remove_job ($num);
    exec 'perl', $0;
  } else {
    require SimGraph::Sim::ARCP;
    my $sim = SimGraph::Sim::ARCP->new ($job);
    
    eval {
      $has_error = 1;
      $sim->$mode;
      $has_error = 0;
    };
    warn $@ if $@;
    
    $sc->remove_job ($num) unless $has_error;
    $sc->error_job ($num) if $has_error;
    $no_job_msg = 1;
  }
}

  msg q<No job> if $no_job_msg;
  $no_job_msg = 0;
  sleep 60;
} # SLEEP

msg q<End>;

__END__

=head1 NAME

startjob.pl - ARCP Simulator - Simulation Job Execution

=head1 SYNOPSIS

  perl startjob.pl

=head1 DESCRIPTION

The C<startjob.pl> starts the execution of the jobs queued by
C<addjob.pl>.

=head1 SEE ALSO

C<bin/addjobs.pl> - Adding a job to the queue

C<stopjob.pl> - Precenting next jobs from execution

C<SimGraph::Scheduler> - Job manger

=head1 AUTHOR

Wakaba <m-wakaba@ist.osaka-u.ac.jp>

=cut

# startjob.pl ends here
