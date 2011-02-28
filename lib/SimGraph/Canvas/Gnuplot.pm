=head1 NAME

SimGraph::Canvas::Gnuplot - ARCP Simulator - Support Module - Gnuplot Canvas

=head1 SYNOPSIS

  require SimGraph::Canvas::Gnuplot;
  my $canvas = SimGraph::Canvas::Gnuplot->new;
  :
  $canvas->draw;

=head1 DESCRIPTION

The C<SimGraph> Perl module set provides various tools to analysis
result files of the ARCP simulator.  The C<SimGraph::Canvas> module
provides an abstract interface to create vector images.
The C<SimGraph::Canvas::Gnuplot> module, a concrete implementation
of C<SimGraph::Canvas> module, can be used to draw the image
using C<gnuplot> (1).

=head1 METHODS

The L<SimGraph::Canvas::Gnuplot> class extends the
L<SimGraph::Canvas> class.  See the documentation
of L<SimGraph::Canvas> for more information on
inheriting methods.

=over 4

=cut

package SimGraph::Canvas::Gnuplot;
use strict;
require SimGraph::Canvas;
require SimGraph::Gnuplot;
push our @ISA, 'SimGraph::Canvas';

sub new ($$) {
  my $class = shift;
  my $self = $class->SUPER::new (@_);
  $self->{plot} = SimGraph::Gnuplot->new;
  $self->{plot}->x_axis ('real');
  $self->{plot}->y_axis ('real');
  $self->{plot}->with_keys (0);
  return $self;
} # new

=item I<$file_name> = I<$c>->gnuplot_data_file_name

Returns the file name used to the input to the C<gnuplot> (1).

=cut

sub gnuplot_data_file_name ($) {
  my ($self) = @_;
  return $self->file_name_stem . '.dat';
} # gnuplot_data_file_name

=item [I<$terminal> =] I<$c>->gnuplot_terminal ([I<$new_terminal>])

Gets and/or sets the output format as used in the C<terminal> method
in L<SimGraph::Gnuplot>.

=cut

sub gnuplot_terminal ($;$) {
  return shift->{plot}->terminal (@_);
} # gnuplot_terminal

=item I<$g>->gnuplot_add_set (I<SET-ARGUMENTS>)

Adds a list of C<gnuplot> (1) C<set> arguments.

=cut

sub gnuplot_add_set ($@) {
  my ($self, @opt) = @_;
  $self->{plot}->add_set (@opt);
} # gnuplot_add_set

=item [I<$ticslevel> =] I<$c>->gnuplot_ticslevel ([I<$new_ticslevel>])

Gets and/or sets the C<ticslevel> for L<SimGraph::Gnuplot>.

=cut

sub gnuplot_ticslevel ($;$) {
  return shift->{plot}->ticslevel (@_);
} # gnuplot_ticslevel

#=item I<$ls> = I<$c>->add_linestyle (type => I<linetype>, width => I<linewidth>)
#
#=cut

sub add_linestyle ($%) {
  my ($self, %opt) = @_;
  return $self->{plot}->add_linestyle (%opt);
} # gnuplot_add_linestyle

sub file_name_stem ($;$) {
  return shift->{plot}->file_name_stem (@_);
} # file_name_stem

sub draw ($) {
  my $self = shift;

  my $data_file_name = $self->gnuplot_data_file_name;
  my @data;
  my $index = 0;
  
  for my $obj (@{$self->{object}}) {
    if ($obj->{type} eq 'line') {
      push @data, join ' ', $obj->{x1}, $obj->{y1}, $obj->{z1} || 0;
      push @data, join ' ', $obj->{x2}, $obj->{y2}, $obj->{z2} || 0;
      $self->{plot}->add_data
          (file_name => $data_file_name, index => $index,
          with => 'lines', linestyle => $obj->{style});
      push @data, '', '';  $index++;
    } elsif ($obj->{type} eq 'circle') {
      push @data, join ' ', $obj->{x}, $obj->{y}, $obj->{z} || 0;
      $self->{plot}->add_data
          (file_name => $data_file_name, index => $index,
          with => 'points', linestyle => $obj->{style});
      push @data, '', '';  $index++;
    } elsif ($obj->{type} eq 'text') {
      $self->{plot}->add_label (%$obj);
    } elsif ($obj->{type} eq 'pointing-label') {
      $self->{plot}->add_pointing_label (%$obj);
    } else {
      warn "Object type $obj->{type} is not supported in Gnuplot canvas\n";
    }
  }
  
  open my $data_file, '>', $data_file_name or die "$0: $data_file_name: $!";
  print $data_file $_, "\n" for @data;
  close $data_file;
  
  $self->{plot}->plot;
} # draw

sub use_z ($;$) {
  return shift->{plot}->use_z (@_);
} # use_z

1;

=back

=head1 SEE ALSO

L<SimGraph::Canvas> - the superclass.

L<SimGraph::Gnuplot> - the C<gnuplot> controler.

=head1 AUTHOR

Wakaba <m-wakaba@ist.osaka-u.ac.jp>

=cut

# Gnuplot.pm ends here
