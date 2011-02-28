=head1 NAME

SimGraph::Scheduler - ARCP Simulator - Simulation Job Scheduler

=head1 DESCRIPTION

The C<SimGraph::Scheduler> Perl module provides a common interface
to the ARCP Simulator's simulation job scheduler.  The scheduler
enables to handle simulation and various graph generation jobs
uniformly.

=head1 SYNOPSIS

  require SimGraph::Scheduler;
  my $sc = SimGraph::Scheduler->new (directory_name => q[./job/]);
  $sc->add_job ({ ... job options ... });

=head1 EVENT HANDLER

=over 4

=cut

use strict;
package SimGraph::Scheduler;
use Fcntl ':flock';
use Data::Dumper;
use SimGraph::IO qw/hostname/;

=item $SimGraph::Scheduler::OnError = I<CODE>

A reference to the code that is invoked when an error is occurred.
The code will receive an argument -
the error message that describes what has happened.  It is expected
to be consumed by a human developer and does not intended
for machine parsing.

The default value is a reference to the code that only invokes
the C<die> with the given message.

=cut

our $OnError = sub ($) {
  my $msg = shift;
  die $msg;
};

=back

=head1 METHODS

=over 4

=item I<$sc> = SimGraph::Scheduler->new (directory_name => I<job-directory-name>)

Creates and returns a new instance of the C<SimGraph::Scheduler> object.

Options:

=over 4

=item directory_name => I<job-directory-name>

The path to the directory in which job files are stored.
The directory SHOULD NOT be used for any other purpose.

=back

=cut

sub new ($;%) {
  my ($class, %opt) = @_;
  my $self = bless {
    directory_name => './job/',
    %opt,
  }, $class;
  $self;
} # new

sub _get_job_file_list ($;%) {
  my ($self, %opt) = @_;
  for (qw/with_waiting with_inprogress with_error/) {
    $opt{$_} = 1 unless defined $opt{$_};
  }
  my $pattern;
  if ($opt{with_waiting}) {
    if ($opt{with_inprogress}) {
      if ($opt{with_error}) {
        $pattern = qr/^\d+\.(?:yet|wip|err)$/;
      } else {
        $pattern = qr/^\d+\.(?:yet|wip)$/;
      }
    } else {
      if ($opt{with_error}) {
        $pattern = qr/^\d+\.(?:yet|err)$/;
      } else {
        $pattern = qr/^\d+\.yet$/;
      }
    }
  } else {
    if ($opt{with_inprogress}) {
      if ($opt{with_error}) {
        $pattern = qr/^\d+\.(?:wip|err)$/;
      } else {
        $pattern = qr/^\d+\.wip$/;
      }
    } else {
      if ($opt{with_error}) {
        $pattern = qr/^\d+\.err$/;
      } else {
        $pattern = qr/(?!)/;
      }
    }
  }
  opendir my $dir, $self->{directory_name};
  return grep /$pattern/, readdir $dir;
} # _get_job_file_list

sub _get_first_job_number ($;%) {
  my ($self, %opt) = @_;
  $opt{start} ||= 0;
  return 0 + ([sort {$a <=> $b} grep {$_ > $opt{start}} $self->_get_job_file_list (with_error => 0, %opt)]->[0] or 0);
} # _get_first_job_number

sub _get_new_job_number ($) {
  my $self = shift;
  my $num = 1 + ([sort {$a <=> $b} $self->_get_job_file_list (with_error => 1)]->[-1] or 10);
  $num = 10 if $num < 10;
  return $num;
} # _get_new_job_number

sub _get_preferred_new_job_number ($) {
  my $self = shift;
  my $num = 1;
  while (1) {
    last if
        not -f "$self->{directory_name}$num.wip" and
        not -f "$self->{directory_name}$num.yet" and
        not -f "$self->{directory_name}$num.err";
    $num++;
  }
  return $num;
} # _get_preferred_new_job_number

sub _lock ($) {
  my $self = shift;
  unless ($self->{lock}) {
    open my $lock, '>', "$self->{directory_name}.lock" or do {
      $OnError->("$0: $self->{directory_name}.lock: $!");
      return;
    };
    flock $lock, LOCK_EX;
    $self->{lock} = $lock;
  }
} # _lock

sub _unlock ($) {
  my $self = shift;
  if ($self->{lock}) {
    flock $self->{lock}, LOCK_UN;
    delete $self->{lock};
  }
} # _unlock

=item I<$num> = I<$sc>->add_job ({I<job-options>}, [preferred => I<boolean>])

Schedules a job.  This method returns the number of the registered job.

Options:

=over 4

=item {I<job-options>}

A reference to the hash that contains various options that describes
the job.

=item preferred => I<boolean> (Default: false)

Whether the job should be processed as far as possible or not.
Note that exactly when the job is processed is undefined.

=back

=cut

sub add_job ($$;%) {
  my ($self, $job, %opt) = @_;
  $self->_lock;
  my $num = $opt{preferred} ? $self->_get_preferred_new_job_number : $self->_get_new_job_number;
  my $job_file_name = $self->{directory_name} . "$num.yet";
  open my $job_file, '>', $job_file_name or do {
    $OnError->("$0: $job_file_name: $!");
    return -1;
  };
  print $job_file Dumper ($job);
  close $job_file;
  $self->_unlock;
  return $num;
} # add_job

sub _get_job ($$) {
  my ($self, $num) = @_;
  my $job_file_name = $self->{directory_name} . $num;
  if (-f $job_file_name . '.yet') {
    $job_file_name .= '.yet';
  } elsif (-f $job_file_name . '.wip') {
    $job_file_name .= '.wip';
  } else {
    $OnError->("$0: $job_file_name.{yet|wip}: File not found");
    return {};
  }
  {
    open my $job_file, '<', $job_file_name or do {
      $OnError->("$0: $job_file_name: $!");
      return {};
    };
    local $/ = undef;
    no strict;
    my $job = eval <$job_file>;
    if ($@) {
      $OnError->("$0: $@");
      return {};
    } elsif (not defined $job) {
      $OnError->("$0: undef");
      return {};
    }
    return $job;
  }
} # _get_job

=item (I<$job>, I<$num>) = I<$sc>->start_first_job

Marks the next waiting job, if any, as work in progress.

If there is a waiting job, then the method returns
the hash reference I<$job> that describes the job (as specified
by the C<add_job> method) and the job number I<$num>.
If there is no waiting job, then C<undef> is returned.

=cut

sub start_first_job ($) {
  my $self = shift;
  $self->_lock;
  my $start;
  J: {
    my $num = $self->_get_first_job_number (with_inprogress => 0, with_waiting => 1, with_error => 0,
        start => $start);
    if ($num > 0) {
      rename "$self->{directory_name}$num.yet" => "$self->{directory_name}$num.wip";
      ## NOTE: Don't use |rename| return value since it seems not work on samba.
      if (-f "$self->{directory_name}$num.yet" and not -f "$self->{directory_name}$num.wip") {
        $OnError->("$0: $self->{directory_name}$num.yet -> .wip: rename: $!");
        $start = $num;
        redo J;
      }
      my $job = $self->_get_job ($num);
      unless (UNIVERSAL::can ($job, 'job_host_allow')) {
        rename "$self->{directory_name}$num.wip" => "$self->{directory_name}$num.yet"
            unless -f "$self->{directory_name}$num.yet";
        $OnError->("$0: Job $num is not a job object");
        redo J;
      }
      
      my $myhostname = hostname;
      ALLOW: {
        for my $hostname (@{$job->job_host_allow}) {
          if ($hostname eq '#any' or $hostname eq $myhostname) {
            last ALLOW;
          }
        }
        $start = $num;
        rename "$self->{directory_name}$num.wip" => "$self->{directory_name}$num.yet"
          or $OnError->("$0: $self->{directory_name}$num.wip -> .yet: rename: $!");
        redo J;
      }
      DENY: for my $hostname (@{$job->job_host_deny}) {
        if ($hostname eq '#any' or $hostname eq $myhostname) {
          $start = $num;
          rename "$self->{directory_name}$num.wip" => "$self->{directory_name}$num.yet"
            or $OnError->("$0: $self->{directory_name}$num.wip -> .yet: rename: $!");
          redo J;
        }
      }
      
      for my $depjob (@{$job->job_depend}) {
        if (-f "$self->{directory_name}$depjob.yet" or
            -f "$self->{directory_name}$depjob.wip") { ## NOTE: .err;.yet are intentionally not checked
          $start = $num;
          rename "$self->{directory_name}$num.wip" => "$self->{directory_name}$num.yet"
            or $OnError->("$0: $self->{directory_name}$num.wip -> .yet: rename: $!");
          redo J;
        }
      }
      $job->job_depend (undef);
      $self->_unlock;
      return ($job, $num);
    } else {
      $self->_unlock;
      return undef;
    }
  } # J
} # start_first_job

=item I<$sc>->remove_job (I<$num>)

Removes a job.

Options:

=over 4

=item I<$num>

The job number.

=back

=cut

sub remove_job ($$) {
  my ($self, $num) = @_;
  $self->_lock;
  (unlink $_ or $OnError->("$0: $_: unlink: $!"))
      for grep -f,
          "$self->{directory_name}$num.yet",
          "$self->{directory_name}$num.wip",
          "$self->{directory_name}$num.err";
  $self->_unlock;
} # remove_job

=item I<$sc>->reset_job (I<$num>)

Resets a job, i.e. bring back to the waiting job queue if the job
is marked as work in progress.

=over 4

=item I<$num>

The job number.

=back

=cut

sub reset_job ($$) {
  my ($self, $num) = @_;
  $self->_lock;
  if (-f "$self->{directory_name}$num.wip") {
    rename "$self->{directory_name}$num.wip" => "$self->{directory_name}$num.yet"
      or $OnError->("$0: $self->{directory_name}$num.wip -> .yet: rename: $!");
  }
  $self->_unlock;
} # reset_job

=item I<$sc>->error_job (I<$num>)

Marks a job as error.

=over 4

=item I<$num>

The job number.

=back

=cut

sub error_job ($$) {
  my ($self, $num) = @_;
  $self->_lock;
  if (-f "$self->{directory_name}$num.wip") {
    rename "$self->{directory_name}$num.wip" => "$self->{directory_name}$num.err"
      or $OnError->("$0: $self->{directory_name}$num.wip -> .err: rename: $!");
  } elsif (-f "$self->{directory_name}$num.yet") {
    rename "$self->{directory_name}$num.yet" => "$self->{directory_name}$num.err"
      or $OnError->("$0: $self->{directory_name}$num.yet -> .err: rename: $!");
  }
  $self->_unlock;
} # error_job

1;

=back

=head1 SEE ALSO

L<bin/addjobs.pl> - Adding jobs.

L<startjob.pl> - Starting the execution of jobs.

L<stopjob.pl> - Stopping the execution of jobs.

L<SimGraph::Param> - The job description object.

=head1 AUTHOR

Wakaba <m-wakaba@ist.osaka-u.ac.jp>

=cut

# Scheduler.pm ends here
