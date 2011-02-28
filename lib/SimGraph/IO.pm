=head1 NAME

SimGraph::IO - ARCP Simulator Support Modules - File I/O and Program Execution

=head1 SYNOPSIS

  use SimGraph::IO qw/xsystem xexec xunlink hostname/;
  
  $SimGraph::IO::OnError = sub {
    my $msg = shift;
    ## Error handling
  };
  
  xsystem 'ls', '-l';
  
  xexec 'echo', 'done';
  
  xunlink 'temp.txt';
  
  my $hostname = hostname;

=head1 DESCRIPTION

The C<SimGraph> Perl module set provides various tools to analysis
result files of the ARCP simulator.  The C<SimGraph::IO> module
provides a set of subroutines to execute an external program.

=head1 VARIABLE

=over 4

=cut

use strict;
package SimGraph::IO;
require Exporter;
push our @ISA, qw(Exporter);
push our @EXPORT_OK, qw/xsystem xexec xunlink hostname/;

=item $SimGraph::IO::OnError = I<CODE>

A reference to the code that is invoked when an error is occurred
while executing the program.  The code will receive an argument -
the error message that describes what is happened.  It is expected
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

=head1 SUBROUTINES

=over 4

=item xsystem I<LIST>

Forks and then executes a program, as does Perl's C<system>.
In addition, it prints arguments (includeing the program name) 
to the standard error output before it is executed.  If the execution
fails, then the C<$SimGraph::IO::OnError> callback function is
invoked.

You can export this subroutine into your package by:

  use SimGraph::IO qw/xsystem/;

=cut

sub xsystem (@) {
  print STDERR join ' ', @_;
  print STDERR "\n";
  
  my $return = system @_;
  if ($return != 0) {
    if ($? == -1) {
      $OnError->("$0: $_[0]: $!");
    } elsif ($? & 127) {
      $OnError->("$0: $_[0]: " . sprintf "died with signal %d, %d coredump",
          ($? & 127), ($? & 128) ? 'with' : 'without');
    } else {
      $OnError->("$0: $_[0]: " . sprintf "exited with value %d", $? >> 8);
    }
  }
  return $return;
} # xsystem

=item xexec I<LIST>

Executes a program replacing current C<perl>, as does Perl's C<exec>.
In addition, it prints arguments (includeing the program name) 
to the standard error output before it is executed.  If the execution
fails, then the C<$SimGraph::IO::OnError> callback function is
invoked.

You can export this subroutine into your package by:

  use SimGraph::IO qw/xexec/;

=cut

sub xexec (@) {
  print STDERR join ' ', @_;
  print STDERR "\n";
  my $return = exec @_;
  $OnError->("$0: $_[0]: $!");
  return $return;
} # xexec

=item xunlink I<file-name>

Removes a file, as does Perl's C<unlink>.
In addition, it prints the file name to the standard error output before it is
removed.  Any error is reported by the same way as C<unlink>.

You can export this subroutine into your package by:

  use SimGraph::IO qw/xunlink/;

=cut

sub xunlink ($) {
  print STDERR join ' ', 'rm', @_;
  print STDERR "\n";
  return unlink @_;
} # xunlink

=item I<$hostname> = hostname

Returns the name of the host, as returned by C<hostname> command.
If there is no C<hostname> command in the searched path,
then an error is thrown.

You can export this subroutine into your package by:

  use SimGraph::IO qw/hostname/;

=cut

my $hostname;
sub hostname () {
  unless (defined $hostname) {
    $hostname = `hostname` or $OnError->("$0: hostname: $!");
    $hostname =~ tr/\x0D\x0A//d;
  }
  return $hostname;
} # hostname

=back

=head1 AUTHOR

Wakaba  <m-wakaba@ist.osaka-u.ac.jp>

=cut

1;
