=head1 NAME

SimGraph::Canvas::XBM - ARCP Simulator - Support Module - X Bitmap (XBM) Canvas

=head1 SYNOPSIS

  require SimGraph::Canvas::XBM;
  my $canvas = SimGraph::Canvas::XBM->new;
  :
  $canvas->draw;

=head1 DESCRIPTION

The C<SimGraph> Perl module set provides various tools to analysis
result files of the ARCP simulator.  The C<SimGraph::Canvas> module
provides an abstract interface to create vector images.
The C<SimGraph::Canvas::XBM> module, a concrete implementation
of C<SimGraph::Canvas> module, can be used to draw a monochrome
image in the XBM format.

=head1 METHODS

The L<SimGraph::Canvas::XBM> class extends the
L<SimGraph::Canvas> class.  See the documentation
of L<SimGraph::Canvas> for more information on
inheriting methods.

=over 4

=cut

package SimGraph::Canvas::XBM;
use strict;
require SimGraph::Canvas;
push our @ISA, 'SimGraph::Canvas';

sub new ($$) {
  my $class = shift;
  my $self = $class->SUPER::new (@_);
  $self->{width} = 1;
  $self->{height} = 1;
  $self->{bitmap} = [[0x00]];
  return $self;
} # new

=over I<$file_name> = I<$self>->xbm_file_name;

Returns the name of the XBM file to be written to
by the C<draw> method.

=cut

sub xbm_file_name ($) {
  my $self = shift;
  return $self->file_name_stem . '.xbm';
} # xbm_file_name

sub set_dot ($$$) {
  my ($self, $pos, $tf) = @_;
  my $x = int ($pos->[0]);
  my $y = int ($pos->[1]);
  $self->{width} = $x + 1 unless $self->{width} > $x;
  $self->{height} = $y + 1 unless $self->{height} > $y;
  if ($tf) {
    $self->{bitmap}->[$y]->[int ($x / 8)] |= (1 << ($x % 8));
  } else {
    $self->{bitmap}->[$y]->[int ($x / 8)] &= 8 & ~(1 << ($x % 8));
  }
} # add_dot

sub draw ($) {
  my $self = shift;
  
  my $name = 'image';
  
  my $width = $self->{width};
  if ($width > int ($width / 8) * 8) {
    $width = int ($width / 8) * 8 + 8;
  }
  my $height = $self->{height};
  
  my $xbm_file_name = $self->xbm_file_name;
  open my $xbm_file, '>', $xbm_file_name or die "$0: $xbm_file_name: $!";

  printf $xbm_file "#define ${name}_width %d\n", $width;
  printf $xbm_file "#define ${name}_height %d\n", $height;
  # #define ${name}_x_spot %d\n
  # #define ${name}_y_spot %d\n
  print $xbm_file "static unsigned char ${name}_bits[] {\n";
  
  for my $y (0..$height-1) {
    for my $x (0..$width/8-1) {
      printf $xbm_file "0x%02X, ", $self->{bitmap}->[$y]->[$x];
    }
    print $xbm_file "\n";
  }
  
  print $xbm_file "};\n";
} # draw

sub use_z ($;$) {
  return 0;
} # use_z

1;

=back

=head1 SEE ALSO

L<SimGraph::Canvas> - the superclass.

=head1 AUTHOR

Wakaba <m-wakaba@ist.osaka-u.ac.jp>

=cut

# XBM.pm ends here
