package HTMLDOMLite;
use strict;

my $html_ns = q<http://www.w3.org/1999/xhtml>;
my $atom_ns = q<http://www.w3.org/2005/Atom>;
my $xml_ns = q<http://www.w3.org/XML/1998/namespace>;
my $xmlns_ns = q<http://www.w3.org/2000/xmlns/>;
my $svg_ns = q<http://www.w3.org/2000/svg>;

sub get_feature ($$;$) {
  return shift;
} # get_feature

sub create_document ($;$$) {
  my ($class, $nsuri, $qname) = @_;
  
  my $doc = HTMLDOMLite::Document->new;
  
  if (defined $qname) {
    my $el = $doc->create_element_ns ($nsuri, $qname);
    $doc->append_child ($el);
  }
  
  return $doc;
} # create_document

sub create_document_type ($$) {
  my (undef, $name) = @_;
  return HTMLDOMLite::DocumentType->new (name => $name);
} # create_document_type

sub dl_create_html_document ($$) {
  my ($self, $title) = @_;
  my $doc = $self->create_document;
  $doc->append_child ($self->create_document_type ('html'));
  for ($doc->append_child ($doc->create_element_ns ($html_ns, 'html'))) {
    $_->append_child ($doc->create_element_ns ($html_ns, 'head'))
        ->append_child ($doc->create_element_ns ($html_ns, 'title'))
        ->text_content ($title);
    $_->append_child ($doc->create_element_ns ($html_ns, 'body'));
  }
  return $doc;
} # dl_create_html_document

sub create_atom_feed_document ($$) {
  my ($self, $feed_tag) = @_;
  my $doc = $self->create_document;
  for ($doc->append_child ($doc->create_element_ns ($atom_ns, 'feed'))) {
    $_->append_child ($doc->create_element_ns ($atom_ns, 'id'))
        ->text_content ($feed_tag);
  }
  return $doc;
} # create_atom_feed_document

package HTMLDOMLite::DOMImplementationRegistry;

$Message::DOM::ImplementationRegistry
    ||= $Message::DOM::DOMImplementationRegistry
    ||= 'HTMLDOMLite::DOMImplementationRegistry';

sub get_dom_implementation ($%) {
  return 'HTMLDOMLite';
} # get_dom_implementation

sub get_dom_implementation_list ($%) {
  return ['HTMLDOMLite'];
} # get_dom_implementation_list

package HTMLDOMLite::Node;

sub new ($%) {
  my $class = shift;
  my $self = bless {child_nodes => [], @_}, $class;
  return $self;
} # new

sub ELEMENT_NODE () { 1 }
sub ATTRIBUTE_NODE () { 2 }
sub TEXT_NODE () { 3 }
sub DOCUMENT_NODE () { 9 }
sub DOCUMENT_TYPE_NODE () { 10 }
sub DOCUMENT_FRAGMENT_NODE () { 11 }

sub child_nodes ($) {
  return shift->{child_nodes};
} # child_nodes

sub dl_get_child_elements_by_tag_name_ns ($$$) {
  my ($self, $nsuri, $lname) = @_;
  my $r = [];
  for (@{$self->{child_nodes}}) {
    push @$r, $_
        if $_->node_type eq HTMLDOMLite::Node::ELEMENT_NODE and $_->namespace_uri eq $nsuri and $_->local_name eq $lname;
  }
  return $r;
} # dl_get_child_elements_by_tag_name_ns

sub append_child ($$) {
  my ($self, $new_child) = @_;
  push @{$self->{child_nodes}}, $new_child;
  return $new_child;
} # append_child

package HTMLDOMLite::Document;
push our @ISA, 'HTMLDOMLite::Node';

sub node_type ($) {
  HTMLDOMLite::Node::DOCUMENT_NODE;
} # node_type

sub create_element_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  my $class = {
    $svg_ns => {
      svg => 'HTMLDOMLite::SVGSVGElement',
    },
  }->{defined $nsuri ? $nsuri : ''}->{$ln} || {
    $svg_ns => 'HTMLDOMLite::SVGElement',
  }->{defined $nsuri ? $nsuri : ''} || 'HTMLDOMLite::Element';
  return $class->new
      (namespace_uri => $nsuri, local_name => $ln, attributes => {});
} # create_element_ns

sub create_text_node ($$) {
  my ($self, $s) = @_;
  return HTMLDOMLite::Text->new (data => $s);
} # create_text_node

sub dl_outer_html ($) {
  return shift->dl_inner_html;
} # dl_outer_html

sub dl_outer_xml ($) {
  return shift->dl_inner_xml;
} # dl_outer_xml

sub dl_inner_html ($) {
  my $self = shift;
  my $r = '';
  for (@{$self->{child_nodes}}) {
    $r .= $_->dl_outer_html;
  }
  return $r;
} # dl_inner_html

sub dl_inner_xml ($) {
  my $self = shift;
  my $r = '';
  for (@{$self->{child_nodes}}) {
    $r .= $_->dl_outer_xml;
  }
  return $r;
} # dl_inner_xml

sub document_element ($) {
  my $self = shift;
  for (@{$self->child_nodes}) {
    return $_ if $_->node_type == HTMLDOMLite::Node::ELEMENT_NODE;
  }
  return undef;
} # document_element

sub dom_config ($) {
  my $self = shift;
  $self->{dom_config} ||= bless {}, 'HTMLDOMLite::DOMConfiguration';
  return $self->{dom_config};
} # dom_config

sub strict_error_checking ($;$) {
  my $self = shift;
  $self->{strict_error_checking} = shift if @_;
  return $self->{strict_error_checking};
} # strict_error_checking

sub body ($) {
  my $self = shift;
  my $root = $self->document_element;
  return undef unless $root;
  return $root->dl_get_child_elements_by_tag_name_ns ($html_ns, 'body')->[0];
} # body

package HTMLDOMLite::DOMConfiguration;

sub get_parameter ($$) {
  my ($self, $cpname) = @_;
  return $self->{lc $cpname};
} # get_parameter

sub set_parameter ($$$) {
  my ($self, $cpname, $value) = @_;
  $self->{lc $cpname} = $value;
} # set_parameter

package HTMLDOMLite::Element;
push our @ISA, 'HTMLDOMLite::Node';

sub node_type ($) {
  HTMLDOMLite::Node::ELEMENT_NODE;
} # node_type

sub text_content ($;$) {
  my $self = shift;
  if (@_) {
    if (length $_[0]) {
      my $text = HTMLDOMLite::Text->new (data => $_[0]);
      @{$self->{child_nodes}} = ($text);
    } else {
      @{$self->{child_nodes}} = ();
    }
  }
  if (defined wantarray) {
    my $r = '';
    for (@{$self->{child_nodes}}) {
      $r .= $_->text_content;
    }
    return $r;
  }
} # text_content

sub local_name ($) {
  return shift->{local_name};
} # local_name

sub namespace_uri ($) {
  return shift->{namespace_uri};
} # namespace_uri

sub dl_inner_html ($) {
  my $self = shift;
  my $r = '';
  for my $node (@{$self->{child_nodes}}) {
    if ($node->node_type == HTMLDOMLite::Node::TEXT_NODE) {
      my $v = $node->text_content;
      $v =~ s/&/&amp;/g;
      $v =~ s/</&lt;/g;
      $v =~ s/>/&gt;/g;
      $v =~ s/"/&quot;/g;
      $r .= $v;
    } else {
      $r .= $node->dl_outer_html;
    }
  }
  return $r;
} # dl_inner_html

sub dl_inner_xml ($) {
  my $self = shift;
  my $r = '';
  for my $node (@{$self->{child_nodes}}) {
    if ($node->node_type == HTMLDOMLite::Node::TEXT_NODE) {
      my $v = $node->text_content;
      $v =~ s/&/&amp;/g;
      $v =~ s/</&lt;/g;
      $v =~ s/>/&gt;/g;
      $v =~ s/"/&quot;/g;
      $r .= $v;
    } else {
      $r .= $node->dl_outer_xml;
    }
  }
  return $r;
} # dl_inner_xml

sub dl_outer_html ($) {
  my $self = shift;
  my $local_name = $self->{local_name};
  my $r = '<' . $local_name;
  for my $nsuri (sort {$a cmp $b} keys %{$self->{attributes}}) {
    for my $ln (sort {$a cmp $b} keys %{$self->{attributes}->{$nsuri}}) {
      my $attr = $self->{attributes}->{$nsuri}->{$ln};
      my $v = $attr->{value};
      $v =~ s/&/&amp;/g;
      $v =~ s/</&lt;/g;
      $v =~ s/>/&gt;/g;
      $v =~ s/"/&quot;/g;
      $r .= ' ';
      $r .= $attr->{prefix} . ':' if length $nsuri;
      $r .= $ln . '="';
      $r .= $v;
      $r .= '"';
    }
  }
  $r .= '>';
  if ($local_name eq 'style' or $local_name eq 'script') {
    $r .= $self->text_content . '</' . $local_name . '>';
  } elsif (not {
    base => 1, img => 1, input => 1, embed => 1, meta => 1, link => 1,
  }->{$local_name}) {
    $r .= $self->dl_inner_html;
    $r .= '</' . $local_name . '>';
  }
  return $r;
} # dl_outer_html

sub dl_outer_xml ($) {
  my $self = shift;
  my $local_name = $self->{local_name};
  my $r = '<';
  my $prefix = '';
  my %nsmap;
  if (defined $self->{namespace_uri}) {
    if (defined $self->{prefix}) {
      $prefix = $self->{prefix} . ':';
      $r .= $prefix;
      $nsmap{$prefix} = $self->{namespace_uri};
    } else {
      $nsmap{''} = $self->{namespace_uri};
    }
  }
  $r .= $local_name;
  ## Note that this method does no namespace fixup but adding namespace declarations
  ## There should be no namespace attributes in {attributes}
  for my $nsuri (sort {$a cmp $b} keys %{$self->{attributes}}) {
    for my $ln (sort {$a cmp $b} keys %{$self->{attributes}->{$nsuri}}) {
      my $attr = $self->{attributes}->{$nsuri}->{$ln};
      my $v = $attr->{value};
      $v =~ s/&/&amp;/g;
      $v =~ s/</&lt;/g;
      $v =~ s/>/&gt;/g;
      $v =~ s/"/&quot;/g;
      $r .= ' ';
      if (length $nsuri) {
        $r .= $attr->{prefix} . ':';
        $nsmap{$attr->{prefix}} = $nsuri;
      }
      $r .= $ln . '="';
      $r .= $v;
      $r .= '"';
    }
  }
  if (defined $nsmap{''}) {
    my $v = $nsmap{''};
    $v =~ s/&/&amp;/g; $v =~ s/</&lt;/g; $v =~ s/>/&gt;/g; $v =~ s/"/&quot;/g;
    $r .= ' xmlns="' . $v . '"';
  }
  delete $nsmap{''};
  for (sort {$a cmp $b} keys %nsmap) {
    my $v = $nsmap{''};
    $v =~ s/&/&amp;/g; $v =~ s/</&lt;/g; $v =~ s/>/&gt;/g; $v =~ s/"/&quot;/g;
    $r .= ' xmlns:' . $_ . '="' . $v . '"';
  }
  my $content = $self->dl_inner_xml;
  if (length $content) {
    $r .= '>';
    $r .= $content;
    $r .= '</' . $prefix . $local_name . '>';
  } else {
    $r .= '/>';
  }
  return $r;
} # dl_outer_xml

sub get_attribute_ns ($$$) {
  my ($self, $nsuri, $ln) = @_;
  my $attr = $self->{attributes}->{$nsuri}->{$ln};
  if ($attr) {
    return $attr->{value};
  } else {
    return undef;
  }
} # get_attribute_ns

sub set_attribute_ns ($$$$) {
  my ($self, $nsuri, $qn, $value) = @_;
  my ($pfx, $ln) = split /:/, $qn, 2;
  ($pfx, $ln) = (undef, $pfx) unless defined $ln;
  $self->{attributes}->{$nsuri}->{$ln} = {value => $value, prefix => $pfx};
} # set_attribute_ns

sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  $AUTOLOAD =~ /([^:]+)$/;
  my $attr_name = $1;
  my $attr_info = { # nsuri, qname, lname, default
    $html_ns => {
      a => {
        href => [undef, 'href', 'href', undef],
      },
      th => {
        scope => [undef, 'scope', 'scope', undef],
      },
    },
    $atom_ns => {
      link => {
        #rel => [undef, 'rel', 'rel', undef], ## TODO: 
        href => [undef, 'href', 'href', undef],
        hreflang => [undef, 'hreflang', 'hreflang', undef],
        type => [undef, 'type', 'type', undef],
      },
      content => {
        type => [undef, 'type', 'type', undef],
      },
    },
    $svg_ns => {
      circle => {
        dl_cx => [undef, 'cx', 'cx', undef],
        dl_cy => [undef, 'cy', 'cy', undef],
        dl_fill => [undef, 'fill', 'fill', undef],
        dl_r => [undef, 'r', 'r', undef],
        dl_stroke => [undef, 'stroke', 'stroke', undef],
        dl_stroke_width => [undef, 'stroke-width', 'stroke-width', undef],
      },
      line => {
        dl_stroke => [undef, 'stroke', 'stroke', undef],
        dl_stroke_width => [undef, 'stroke-width', 'stroke-width', undef],
        dl_x1 => [undef, 'x1', 'x1', undef],
        dl_y1 => [undef, 'y1', 'y1', undef],
        dl_x2 => [undef, 'x2', 'x2', undef],
        dl_y2 => [undef, 'y2', 'y2', undef],
      },
      text => {
        dl_fill => [undef, 'fill', 'fill', undef],
        dl_stroke => [undef, 'stroke', 'stroke', undef],
        dl_text_anchor => [undef, 'text-anchor', 'text-anchor', undef],
        dl_x => [undef, 'x', 'x', undef],
        dl_y => [undef, 'y', 'y', undef],
      },
    },
  }->{$self->{namespace_uri}}->{$self->{local_name}}->{$attr_name} || {
    $html_ns => {
      title => [undef, 'title', 'title', undef],
    },
  }->{$self->{namespace_uri}}->{$attr_name};
  ## TODO: atom:feed -> title_element 
  ## atom:author->name, ->uri, ->email
  ## entry published_element title_element content_element  published_el,ement
  ## content container
  if ($attr_info) {
    if (@_) {
      $self->set_attribute_ns ($attr_info->[0], $attr_info->[1], $_[0]);
    }
    if (defined wantarray) {
      my $v = $self->get_attribute_ns ($attr_info->[0], $attr_info->[2]);
      return defined $v ? $v : $attr_info->[3];
    }
  } else {
    die "Can't locate method $AUTOLOAD";
  }
} # AUTOLOAD

package HTMLDOMLite::SVGElement;
push our @ISA, 'HTMLDOMLite::Element';

sub dl_title ($;$) {
  ## BUG: can't rewrite
  ## BUG: no getter
  my $self = shift;
  my $title = HTMLDOMLite::Document->create_element_ns ($svg_ns, 'title');
  $title->text_content (shift);
  $self->append_child ($title);
  return undef;
} # dl_desc

package HTMLDOMLite::SVGSVGElement;
push our @ISA, 'HTMLDOMLite::SVGElement';

my $extract_vb = sub ($) {
  my $self = shift;
  my $vb = $self->get_attribute_ns (undef, 'viewBox');
  my $vbx = defined $vb ? [split /\s+(?:,\s)?/, $vb, 5] : [];
  $vbx->[0] = '0' unless defined $vbx->[0];
  $vbx->[1] = '0' unless defined $vbx->[1];
  $vbx->[2] = '-1' unless defined $vbx->[2];
  $vbx->[3] = '-1' unless defined $vbx->[3];
  return $vbx;
};

sub dl_viewbox_min_x ($;$) {
  my $self = shift;
  my $vb = $extract_vb->($self);
  if (@_) {
    $vb->[0] = shift;
    $self->set_attribute_ns (undef, 'viewBox', join ' ', @$vb);
  }
  return $vb->[0];
} # dl_viewbox_min_x

sub dl_viewbox_min_y ($;$) {
  my $self = shift;
  my $vb = $extract_vb->($self);
  if (@_) {
    $vb->[1] = shift;
    $self->set_attribute_ns (undef, 'viewBox', join ' ', @$vb);
  }
  return $vb->[1];
} # dl_viewbox_min_y

sub dl_viewbox_width ($;$) {
  my $self = shift;
  my $vb = $extract_vb->($self);
  if (@_) {
    $vb->[2] = shift;
    $self->set_attribute_ns (undef, 'viewBox', join ' ', @$vb);
  }
  return $vb->[2];
} # dl_viewbox_width

sub dl_viewbox_height ($;$) {
  my $self = shift;
  my $vb = $extract_vb->($self);
  if (@_) {
    $vb->[3] = shift;
    $self->set_attribute_ns (undef, 'viewBox', join ' ', @$vb);
  }
  return $vb->[3];
} # dl_viewbox_height

package HTMLDOMLite::Text;
push our @ISA, 'HTMLDOMLite::Node';

sub node_type ($) {
  HTMLDOMLite::Node::TEXT_NODE;
} # node_type

sub text_content ($;$) {
  my $self = shift;
  $self->{data} = shift if @_;
  return $self->{data};
} # text_content

package HTMLDOMLite::DocumentType;
push our @ISA, 'HTMLDOMLite::Node';

sub node_type ($) {
  HTMLDOMLite::Node::DOCUMENT_TYPE_NODE;
} # node_type

sub dl_outer_html ($) {
  my $self = shift;
  return '<!DOCTYPE ' . $self->{name} . ">\n";
} # dl_outer_html

sub dl_outer_xml ($) {
  my $self = shift;
  return '<!DOCTYPE ' . $self->{name} . ">\n";
} # dl_outer_xml

1;
