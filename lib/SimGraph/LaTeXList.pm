=head1 NAME

SimGraph::LaTeXList - ARCP Simulator - Support Module - LaTeX Graph List
Generation

=head1 SYNOPSIS

  require SimGraph::LaTeXList;
  my $l = SimGraph::LaTeXList->new;
  $l->file_name_stem ($file_name_without_suffix);
  :
  $l->stringify;
  $l->make_pdf;

=head1 DESCRIPTION

The L<SimGraph> Perl module set provides facilities to execute
ARCP simulator and to analyse its results.
With the L<SimGraph::LaTeXList> module, Perl scripts can
generate a LaTeX source file that contains a list of graphes
extracted from various visualizing scripts.

=head1 METHODS

=over 4

=cut

use strict;
package SimGraph::LaTeXList;
use SimGraph::IO qw/xsystem/;

=item I<$l> = SimGraph::LaTeXList->new;

Creates and returns a new instance of the L<SimGraph::LaTeXList>.

=cut

sub new ($) {
  my $self = bless {content => ''}, shift;
  $self;
} # new

=item I<$tex_content> = I<$l>->stringify

Returns the textual representation of the content
of the LaTeX source file.

=cut

sub stringify ($) {
  my $self = shift;
  my $r = $self->stringify_header;
  $r .= $self->{content};
  $r .= $self->stringify_footer;
  $r;
} # stringify

sub stringify_header ($) {
<<'EOH';
    \documentclass[notitlepage,a4j,10pt]{jarticle}
    \usepackage{txfonts}
    \usepackage[dvips]{graphicx}

    \pagestyle{empty}
%    \setlength{\topmargin}{10mm}
%    \addtolength{\topmargin}{-1in}
%    \setlength{\oddsidemargin}{3mm}
%    \addtolength{\oddsidemargin}{-1in}
%    \setlength{\evensidemargin}{3mm}
%    \addtolength{\evensidemargin}{-1in}
    \usepackage{fullpage}
    \addtolength{\textheight}{4cm}

    \newcommand{\scale}{0.18}
    \newcommand{\graphlistscale}{0.24}
    \newcommand{\rpgraphlistscale}{0.48}
    \newcommand{\receptmeanscale}{0.70}
    \newcommand{\receptvariancescale}{0.70}
    \newcommand{\visitmeanscale}{0.70}
    \newcommand{\rpanttwodscale}{0.47}
    \newcommand{\rpmovedscale}{0.70}
    \newcommand{\routegraphlistscale}{0.35}
    
    \setlength{\parindent}{0pt}

    \begin{document}

EOH
} # stringify_header

sub stringify_footer ($) {
<<'EOH'
    \end{document}
EOH
} # stringify_footer

=item [L<$new_file_name_stem> =] I<$l>->file_name_stem ([I<$file_name_stem>]);

Gets and/or sets the main part of the LaTeX source file and
various supporting files, including the PDF file.  If it is not
explicitly specified, then C<temp> is returned.

=cut

sub file_name_stem ($;$) {
  my $self = shift;
  $self->{file_name_stem} = shift if @_;
  defined $self->{file_name_stem} ? $self->{file_name_stem} : 'temp';
} # file_name_stem

=item I<$l>->add_content (L<$tex_fragment>)

Adds a LaTeX fragment at the end of the body part of the LaTeX
source file content.

=over 4

=item I<$tex_fragment>

The fragment of the LaTeX source code.

=back

=cut

sub add_content ($$) {
  my $self = shift;
  $self->{content} .= shift;
} # add_content

=item I<$l>->add_tex_section (I<$section_title>)

A convenience method to do C<add_content> with the parameter
enclosed by LaTeX C<\section{}> command.

=over 4

=item I<$section_title>

The LaTeX fragment used as the title of the section.

=back

=cut

sub add_tex_section ($$) {
  my ($self, $s) = @_;
  $self->add_content ('\section{' . $s . '}');
} # add_tex_section

=item I<$l>->add_tex_source_comment (I<$comment>)

A convenience method to do C<add_content> to insert
the parameter as a comment in the LaTeX source file.

=over 4

=item I<$comment>

The comment string.  It MAY contain newline characters.

=back

=cut

sub add_tex_source_comment ($$) {
  my ($self, $s) = @_;
  $s =~ s/\n/\n% /gs;
  $self->add_content ('% ' . $s . "\n");
} # add_tex_source_comment

=item I<$l>->add_tex_source_newline

A convenience method to do C<add_content> with a newline
character.

=cut

sub add_tex_source_newline ($) {
  shift->add_content ("\n");
} # add_tex_source_newline

=item I<$l>->add_tex_newpara

A convenience method to do C<add_content> with
a new paragraph command (i.e. doubled newline characters).

=cut

sub add_tex_newpara ($) {
  shift->add_content ("\n\n");
} # add_tex_newpara

=item I<$l>->add_tex_newpage

A convenience method to do C<add_content> with a
LaTeX C<\newpage> command.

=cut

sub add_tex_newpage ($) {
  shift->add_content ('\newpage');
} # add_tex_newpage

=item I<$l>->add_tex_image (I<OPTIONS>)

A convenience method to do C<add_content> with a
LaTeX image inserting command.

=over 4

=item file_name => I<$file_name> (Required)

The name of the image file.

=item scale => I<$latex_scale> (Default: none)

The LaTeX fragment to represent the scale.

=back

=cut

sub add_tex_image ($%) {
  my ($self, %opt) = @_;
  my $opt = '';
  $opt .= 'scale=' . $opt{scale} if defined $opt{scale};
  my $file_name = $self->_get_relative_file_name ($opt{file_name});
  $self->add_content (qq[\\includegraphics[$opt]{$file_name}]);
} # add_tex_image

sub _get_relative_file_name ($$) {
  my ($self, $given) = @_;
  require File::Spec;
  my $base = File::Spec->rel2abs ("$self->file_name_stem.tex");
  my $given = File::Spec->rel2abs ($given);
  return File::Spec->abs2rel ($given, $base);
} # _get_relative_file_name

=item I<$l>->make_pdf

Writes a LaTeX source file and then executes the C<make> (1)
command with the corresponding PDF file name given as an argument
to that program.

Exception:

=over 4

=item Perl C<die>

This method will C<die> if an attempt to open a LaTeX source file
for writing fails.

=item Any exception

This method utilizes the C<xsystem> function provided by the
L<SimGraph::IO> module.  If the error handler is specified as defined
by that module to throw an exception, then the exception
is propagated up through this method.

=back

=cut

sub make_pdf ($) {
  my $self = shift;
  my $file_name_stem = $self->file_name_stem;
  my $tex_file_name = "$file_name_stem.tex";
  #my $pdf_file_name = "$file_name_stem.pdf";
  
  open my $tex_file, '>', $tex_file_name or die "$0: $tex_file_name: $!";
  print $tex_file $self->stringify;
  close $tex_file;
  
  my $file_dir = '.';
  if ($file_name_stem =~ s!^((?:.*)/)!!) {
    $file_dir = $1;
  }
  use Cwd;
  my $dir = cwd ();
  chdir $file_dir;
  #xsystem 'make', $pdf_file_name;
  xsystem 'platex', "-halt-on-error", "$file_name_stem.tex";
  xsystem 'dvips', "$file_name_stem.dvi";
  xsystem 'ps2pdf', "$file_name_stem.ps" => "$file_name_stem.pdf";
  chdir $dir;
} # make_pdf

1;

=back

=head1 AUTHOR

Wakaba <m-wakaba@ist.osaka-u.ac.jp>

=cut

# LaTeXList.pm ends here
