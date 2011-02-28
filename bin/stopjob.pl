#!/usr/bin/perl
use strict;

my $JOB_DIRECTORY_NAME = './job/';
my $ALLOWED_HOST = [];
my $DENIED_HOST = [];
my $MODE = 'stop';

use Getopt::Long;
use Pod::Usage;
GetOptions (
  'help' => sub { pod2usage 1 },
  'host-allow=s' => sub { shift; push @$ALLOWED_HOST, shift },
  'host-deny=s' => sub { shift; push @$DENIED_HOST, shift },
  'job-directory-name=s' => \$JOB_DIRECTORY_NAME,
  'restart' => sub { $MODE = 'restart' },
  'stop' => sub { $MODE = 'stop' },
) or pod2usage 2;
$ALLOWED_HOST = ['#any'] if @$ALLOWED_HOST == 0;

sub msg (@) { print STDERR '[', scalar localtime, '] ', @_, "\n" }

use SimGraph::Scheduler;
use SimGraph::Param::ARCPSim;

my $sc = SimGraph::Scheduler->new (directory_name => $JOB_DIRECTORY_NAME);

my $job = SimGraph::Param::ARCPSim->new;
$job->output_type ($MODE eq 'restart' ? 'job_restart' : 'job_stop');
$job->job_host_allow ($ALLOWED_HOST);
$job->job_host_deny ($DENIED_HOST);

$sc->add_job ($job->job, preferred => 1);
msg $MODE eq 'restart' ? q<Scheduled to restart> : q<Scheduled to stop>;

__END__

=head1 NAME

stopjob.pl - ARCP Simulator - Stopping or Restarting the Simulation

=head1 SYNOPSIS

  perl stopjob.pl [--stop] [OPTIONS]
  perl stopjob.pl --restart [OPTIONS]
  perl stopjob.pl --help

=head1 DESCRIPTION

The C<stopjob.pl> Perl script can be used to schedule to stop
or restart the ongoing simulation as far as possible.

This script schedule a pseudo-job to stop or restart the simulation
scheduler with the smallest but unused job number.  It never
distrubs the current (executing) job.  In the worst case,
where all the job number from zero to the largest job number
are reserved, the pseudo-job cannot be executed until
any existing job is done (although this is unlikely happened,
since the first job number assigned to a normal job is set to
eleven).

=head1 OPTIONS

=over 4

=item --help

Show the help message and then exit the script without
scheduling any job.  Any other options are ignored.

=item --job-directory-name=I<directory-name> (Default: C<./job/>)

The directory in which the job awaiting execution are spoolled.

=item --host-allow=I<host-name> (Default: C<#any> only)

The name of the host that may execute the job registered.
A special token, C<#job>, can be specified to allow any
host execute the job.  This option can be specified more than once;
all hosts specified are allowed.

=item --host-deny=I<host-name> (Default: none)

The name of the host that must not execute the job registered.
A special token, C<#job>, can be specified to allow any
host execute the job.  This option can be specified more than once;
all hosts specified are denied.  This option take precedence over
the C<--host-allow> option.

=item --restart

Schedule to restart the simulation scheduler.

=item --stop

Schedule to stop the simulation scheduler.  This is the default option
used when no option is specified.

=back

=head1 SEE ALSO

L<startjob.pl> - ARCP Simulation Scheduler

L<bin/addjobs.pl> - ARCP Simulation Job Register

L<SimGraph::Scheduler> - Perl Module for Job Scheduling

=head1 AUTHOR

Wakaba <m-wakaba@ist.osaka-u.ac.jp>

=cut

# stopjob.pl ends here
