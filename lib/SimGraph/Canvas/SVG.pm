=head1 NAME

SimGraph::Canvas::SVG - ARCP Simulator - Support Module - SVG Canvas

=head1 SYNOPSIS

  require SimGraph::Canvas::SVG;
  my $canvas = SimGraph::Canvas::SVG->new;
  :
  $canvas->draw;

=head1 DESCRIPTION

The C<SimGraph> Perl module set provides various tools to analysis
result files of the ARCP simulator.  The C<SimGraph::Canvas> module
provides an abstract interface to create vector images.
The C<SimGraph::Canvas::SVG> module, a concrete implementation
of C<SimGraph::Canvas> module, can be used to draw a monochrome
image in the SVG format.

=head1 METHODS

The L<SimGraph::Canvas::SVG> class extends the
L<SimGraph::Canvas> class.  See the documentation
of L<SimGraph::Canvas> for more information on
inheriting methods.

=over 4

=cut

package SimGraph::Canvas::SVG;
use strict;
require SimGraph::Canvas;
push our @ISA, 'SimGraph::Canvas';

sub SVGNS { q<http://www.w3.org/2000/svg> }

sub new ($$) {
  my $class = shift;
  my $self = $class->SUPER::new (@_);
  $self->{linestyle} = [];
  $self->add_linestyle (); # default
  return $self;
} # new

sub add_linestyle ($%) {
  my ($self, %opt) = @_;
  if ($opt{inherit}) {
    %opt = (%{$self->{linestyle}->[$opt{inherit}] or {}}, %opt);
    delete $opt{linestyle};
  }
  push @{$self->{linestyle}}, \%opt;
  return $#{$self->{linestyle}};
} # add_linestyle

=over I<$file_name> = I<$self>->svg_file_name;

Returns the name of the SVG file to be written to
by the C<draw> method.

=cut

sub svg_file_name ($) {
  my $self = shift;
  return $self->file_name_stem . '.svg';
} # svg_file_name

sub draw ($) {
  my $self = shift;
  
  require HTMLDOMLite;
  my $doc = HTMLDOMLite->create_document (SVGNS, 'svg');
  my $docel = $doc->document_element;
  
  my $min_x = 0;
  my $min_y = 0;
  my $max_x = 0;
  my $max_y = 0;
  my $set_x = sub ($) { my $v = shift; $max_x = $v if $max_x < $v; $min_x = $v if $min_x > $v; return $v  };
  my $set_y = sub ($) { my $v = shift; $max_y = $v if $max_y < $v; $min_y = $v if $min_y > $v; return $v  };
  
  for my $obj (@{$self->{object}}) {
    if ($obj->{type} eq 'line') {
      my $el = $doc->create_element_ns (SVGNS, 'line');
      $el->dl_x1 ($set_x->($obj->{x1}));
      $el->dl_y1 ($set_y->($obj->{y1}));
      $el->dl_x2 ($set_x->($obj->{x2}));
      $el->dl_y2 ($set_y->($obj->{y2}));
      $el->dl_title ($obj->{title}) if defined $obj->{title};
      
      my $linestyle = $self->{linestyle}->[$obj->{style}];
      $el->dl_stroke ($linestyle->{color}) if defined $linestyle->{color};
      $el->dl_stroke_width ($linestyle->{width}) if defined $linestyle->{width};
      
      $docel->append_child ($el);
    } elsif ($obj->{type} eq 'circle') {
      my $el = $doc->create_element_ns (SVGNS, 'circle');
      $el->dl_cx ($obj->{x});
      $el->dl_cy ($obj->{y});
      $el->dl_r ($obj->{r});
      $set_x->($obj->{x}-$obj->{r}); $set_y->($obj->{y}-$obj->{r});
      $set_x->($obj->{x}+$obj->{r}); $set_y->($obj->{y}+$obj->{r});
      $el->dl_title ($obj->{title}) if defined $obj->{title};
      
      my $linestyle = $self->{linestyle}->[$obj->{style}];
      $el->dl_fill ($linestyle->{color}) if defined $linestyle->{color};
      $el->dl_stroke ($linestyle->{color}) if defined $linestyle->{color};
      $el->dl_stroke_width ($linestyle->{width}) if defined $linestyle->{width};
      
      $docel->append_child ($el);
    } elsif ($obj->{type} eq 'text') {
      my $el = $doc->create_element_ns (SVGNS, 'text');
      $el->dl_x ($set_x->($obj->{x}));
      $el->dl_y ($set_y->($obj->{y}));
      $el->dl_text_anchor ({left => 'start', right => 'end'}->{$obj->{text_anchor}} or $obj->{text_anchor})
          if defined $obj->{text_anchor};
      
      my $linestyle = $self->{linestyle}->[$obj->{style}];
      $el->dl_fill ($linestyle->{color}) if defined $linestyle->{color};
      $el->dl_stroke ($linestyle->{color}) if defined $linestyle->{color};
      
      $docel->append_child ($el);
    } elsif ($obj->{type} eq 'pointing-label') {
      ## Taken from SimGraph::Gnuplot
      my $anchor_x = $obj->{x2} || 0;
      my $anchor_y = $obj->{y2} || 0;
      ## NOTE: Suitable value only for gnuplot screen
      my $text_width = 0.014 * length $obj->{title};
      my $padding_horizontal = 0.02;
      $obj->{text_anchor} ||= 'left';
      my $text_x = $anchor_x;
      $text_x =~ s/([0-9.]+)/$1 - $text_width/e if $obj->{text_anchor} eq 'right';
      my $text_y = $anchor_y;
      my $joint_x = $anchor_x;
      my $joint_y = $anchor_y;
      $joint_x =~ s/([0-9.]+)/$1 + $padding_horizontal * ($obj->{text_anchor} eq 'right' ? 0 : -1)/e;
      $joint_y =~ s/([0-9.]+)/$1 - $padding_horizontal/e;
      my $another_x = $joint_x;
      my $another_y = $joint_y;
      $another_x =~ s/([0-9.]+)/$1 + ($text_width + $padding_horizontal)
          * ($obj->{text_anchor} eq 'right' ? -1 : 1)/e;
      
      my $linestyle = $self->{linestyle}->[$obj->{style}];
      
      my $line1 = $doc->create_element_ns (SVGNS, 'line');
      $line1->dl_x1 ($set_x->($obj->{x1} or 0));
      $line1->dl_y1 ($set_y->($obj->{y1} or 0));
      $line1->dl_x2 ($set_x->($joint_x or 0));
      $line1->dl_y2 ($set_y->($joint_y or 0));
      $line1->dl_stroke ($linestyle->{color}) if defined $linestyle->{color};
      $line1->dl_stroke_width ($linestyle->{width}) if defined $linestyle->{width};
      $docel->append_child ($line1);
      
      my $line2 = $doc->create_element_ns (SVGNS, 'line');
      $line2->dl_x1 ($set_x->($another_x or 0));
      $line2->dl_y1 ($set_y->($another_y or 0));
      $line2->dl_x2 ($joint_x or 0);
      $line2->dl_y2 ($joint_y or 0);
      $line2->dl_stroke ($linestyle->{color}) if defined $linestyle->{color};
      $line2->dl_stroke_width ($linestyle->{width}) if defined $linestyle->{width};
      $docel->append_child ($line2);
      
      my $text = $doc->create_element_ns (SVGNS, 'text');
      $text->dl_x ($set_x->($text_x));
      $text->dl_y ($set_y->($text_y));
      $text->text_content ($obj->{title});
      $docel->append_child ($text);
    } else {
      warn "Object type $obj->{type} is not supported in SVG canvas\n";
    }
  }
  
  $docel->dl_viewbox_min_x ($min_x);
  $docel->dl_viewbox_min_y ($min_y);
  $docel->dl_viewbox_width ($max_x - $min_x);
  $docel->dl_viewbox_height ($max_y - $min_y);
  
  my $svg_file_name = $self->svg_file_name;
  open my $svg_file, '>', $svg_file_name or die "$0: $svg_file_name: $!";
  print $svg_file $doc->dl_outer_xml;
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

# SVG.pm ends here
