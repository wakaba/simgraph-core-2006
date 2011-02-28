=head1 NAME

SimGraph::Canvas - Simulation and Graph-generation utilities - Canvas base class

=head1 SYNOPSIS

  require SimGraph::Canvas::Gnuplot;
  my $canvas = SimGraph::Canvas::Gnuplot->new;
  :
  $canvas->draw;

=head1 DESCRIPTION

The C<SimGraph::Canvas> module provides an abstract interface to
create vector images.

It is I<not> intended for this module to be used by scripts directly;
C<SimGraph::Canvas::Gnuplot>, for example, inherits this module and
implements drawing of vector images using C<gnuplot> (1).

=head1 METHODS

=over 4

=cut

package SimGraph::Canvas;
use strict;

=item I<$c> = I<SimGraph::Canvas-subclass>->new ([I<OPTIONS>])

Creates and returns a new instance of the C<SimGraph::Canvas> object.
You can't instantiate the C<SimGraph::Canvas> class itself;
instead, one of subclass of that module must be specified.

=cut

sub new ($) {
  my ($class) = @_;
  my $self = bless {object => []}, $class;
  return $self;
} # new

=item [I<$file_name_stem> =] I<$c>->file_name_stem ([I<$new_file_name_stem>])

Gets and/or sets the main part of the file name used to input and/or
output to the canvas.  It MAY contain the directory part of the file name.

=cut

sub file_name_stem ($;$) {
  my ($self, $stem) = @_;
  $self->{file_name_stem} = $stem if @_ > 1;
  return $self->{file_name_stem} || 'temp';
} # file_name_stem

=item I<$ls> = I<$c>->add_linestyle (type => I<linetype>, width => I<linewidth>)

Defines a style to draw line in this canvas.  The method
returns the linestyle identifier, which deoends on
the type of the canvas.

If the canvas does not support the linstyle feature, then
this method has no effect and it returns C<undef>.

Options:

=over 4

=item color => I<< <color> >> (Default: auto)

The color of the line.  Some subset of CSS I<< <color> >>, depending on
the type of the canvas, possibily empty subset, is allowed as values to this option.

=item type => I<linetype> (Default: auto)

The type of the line.  Allowed values depend on the type of the canvas.
Required for gnuplot canvas.

=item width => I<linewidth> (Required)

The width of the line.  Allowed values depend on the type of the canvas.
For gnuplot canvas, a positive number is allowed.
For SVG canvas, a legal SVG I<< <length> >> value is allowed.

=back

=cut

sub add_linestyle ($%) {
  my $self = shift;
  warn "Method |add_linestyle| has no effect for |" . ref $self . "|\n";
} # add_linestyle

=item I<$c>->add_line ([I<$x1>, I<$y1>, I<$z1>], [I<$x2>, I<$y2>, I<$z2>], I<OPTIONS>)

Appends a line to the list of objects in the canvas.

Options:

=over 4

=item [I<$x1>, I<$y1>, I<$z1> (Default: 0)], [I<$x2>, I<$y2>, I<$z2> (Default: 0)]

The coordinate of the ends of the line.  If C<$z1> or C<$z2> is set to a value
different from C<0>, then the C<< I<$c>->use_z >> property
is set to true.

Note that the first and second arguments to the method are array references and 
MUST be present, while the C<$z1> and the C<$z2> parameters are optional.

=item style => I<style-id> (Default: none)

The style of the line.  It MUST be a value returned
by C<< I<$c>->add_linestyle >>.

=back

=cut

sub add_line ($$$%) {
  my ($self, $p1, $p2, %opt) = @_;
  push @{$self->{object}}, bless
      {%opt,
      type => 'line',
      x1 => $p1->[0]||0, y1 => $p1->[1]||0, z1 => $p1->[2]||0,
      x2 => $p2->[0]||0, y2 => $p2->[1]||0, z2 => $p2->[2]||0}
  , 'SimGraph::Canvas::Object';
  $self->use_z (1) if $p1->[2] or $p2->[2];
} # add_line

=item I<$c>->add_text (I<$text>, [I<$x>, I<$y>, I<$z>], I<OPTIONS>)

Appends a text to the list of objects in the canvas.

Options:

=over 4

=item I<$text> (Required)

The text to render.

=item [I<$x>, I<$y>, I<$z> (Default: 0)]

The coordinate of the ends of the line.  If C<$z> is set to a value
different from C<0>, then the C<< I<$c>->use_z >> property
is set to true.

=item style => I<style-id> (Default: none)

The style of the line.  It MUST be a value returned
by C<< I<$c>->add_linestyle >>.

=back

=cut

sub add_text ($$$%) {
  my ($self, $text, $p, %opt) = @_;
  push @{$self->{object}}, bless {
      %opt,
      type => 'text',
      x => $p->[0]||0, y => $p->[1]||0, z => $p->[2]||0,
      title => $text,
  }, 'SimGraph::Canvas::Object';
  $self->use_z (1) if $p->[2];
} # add_text

=item I<$c>->add_circle (I<$text>, [I<$x>, I<$y>, I<$z>], I<OPTIONS>)

Appends a circle to the list of objects in the canvas.

Options:

=over 4

=item [I<$x>, I<$y>, I<$z> (Default: 0)]

The coordinate of the ends of the line.  If C<$z> is set to a value
different from C<0>, then the C<< I<$c>->use_z >> property
is set to true.

=item I<$r> (Required)

The radius of the circle.

=item style => I<style-id> (Default: none)

The style of the line.  It MUST be a value returned
by C<< I<$c>->add_linestyle >>.

=back

=cut

sub add_circle ($$$%) {
  my ($self, $p, $r, %opt) = @_;
  push @{$self->{object}}, bless {
      %opt,
      type => 'circle',
      x => $p->[0]||0, y => $p->[1]||0, z => $p->[2]||0,
      r => $r,
  }, 'SimGraph::Canvas::Object';
  $self->use_z (1) if $p->[2];
} # add_circle

=item $c->add_pointing_label (...)

@@

=cut

sub add_pointing_label ($$$$%) {
  my ($self, $from, $to, $label, %opt) = @_;
  push @{$self->{object}}, bless {
      %opt,
      type => 'pointing-label',
      x1 => $from->[0]||0, y1 => $from->[1]||0, z1 => $from->[2]||0,
      x2 => $to->[0]||0, y2 => $to->[1]||0, z2 => $to->[2]||0,
      title => $label,
  }, 'SimGraph::Canvas::Object';
} # add_pointing_label

=item [I<$use_z> =] I<$g>->use_z ([I<$new_use_z>]);

Gets and/or sets whether the z-axis is rendered or not,
in other word the canvas is rendered as in 3-D or not.

=cut

sub use_z ($;$) {
  my $self = shift;
  $self->{use_z} = shift if @_;
  return $self->{use_z};
} # use_z

sub for_each_object ($$;%) {
  my ($self, $code, %opt) = @_;
  for my $obj (@{$self->{object} or []}) {
    next if defined $opt{class} and not $obj->{class} eq $opt{class};
    $code->($obj);
  }
} # for_each_object

package SimGraph::Canvas::Object;

sub linestyle ($;$) {
  my $self = shift;
  if (@_) {
    $self->{style} = shift;
  }
  return $self->{style};
} # set_linestyle

sub title ($;$) {
  my $self = shift;
  if (@_) {
    $self->{title} = shift;
  }
  return $self->{title};
} # title

sub node_id ($;$) {
  my $self = shift;
  if (@_) {
    $self->{node_id} = shift;
  }
  return $self->{node_id};
} # node_id

1;

=back

=head1 EXAMPLES

=head2 Example 1 - Draw on gnuplot canvas

  require SimGraph::Canvas::Gnuplot;
  my $canvas = SimGraph::Canvas::Gnuplot->new;
  $canvas->file_name_stem ($OUTPUT_FILE_NAME_STEM);
  $canvas->gnuplot_terminal ($OUTPUT);
  $canvas->gnuplot_ticslevel (0);
  $canvas->gnuplot_add_set (xtics => 1);
  $canvas->gnuplot_add_set (ytics => 1);
  
  my $ss_line_style = $canvas->add_linestyle (type => 3, width => 1);
  my @line_style;
  $line_style[$_] = $canvas->add_linestyle
      (type => [10, 8, 4, 2]->[$_], width => 1) for 0..3;
  
  for my $i (0..$#point-1) {
    $canvas->add_line ($point[$i] => $point[$i+1],
                       style => $line_style[$delta]);
  }
  
  $canvas->add_text ($text, [$x/2 + 0.1, $y/2 + 0.1]);
  
  $canvas->add_circle ([$v, 0, 0], 5, style => $ss_line_style);
  $canvas->add_pointing_label ($coord => ['screen 0.82', 'screen 0.77'],
                               $v, linestyle => $sink_line_style);
  
  $canvas->draw;

=head2 Example 2 - Enumerate objects and set properties

  my $canvas = SimGraph::Canvas::SVG->new;
  
  ...
  
  $canvas->for_each_object (sub {
    my $obj = shift;
    my $color = ...;
    my $ls = $canvas->add_linestyle
        (inherit => $obj->linestyle, color => $color);
    $obj->linestyle ($ls);
    $obj->title ($obj->node_id . ': ' . $prob);
  }, class => 'node');
  
  warn "Writing $file_name_stem.svg...\n";
  $canvas->file_name_stem ($file_name_stem);
  $canvas->draw;

=head2 Example 3 - Generate a bitmap image

  require SimGraph::Canvas::XBM;
  
  my $xbm = SimGraph::Canvas::XBM->new;
  $xbm->file_name_stem ($OUTPUT_FILE_NAME_STEM);
  
  $xbm->set_dot ([$x => $y] => $v);
  
  $xbm->draw;

=head1 SEE ALSO

L<SimGraph::Canvas::Gnuplot>, L<SimGraph::Canvas::SVG>,
L<SimGraph::Canvas::XBM>.

=head1 AUTHOR

Wakaba <w@suika.fam.cx>.

=head1 LICENSE

Copyright 2006-2007 Wakaba <w@suika.fam.cx>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
