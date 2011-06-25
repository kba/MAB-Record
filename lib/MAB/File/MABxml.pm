package MAB::File::MABxml;

=head1 NAME

MAB::File::MABxml - Serialization & Deserialization of MABxml data

=cut

use strict;
use warnings;
use charnames  ':full';
use vars qw( $ERROR );
use MAB::File;
use vars qw( @ISA );
@ISA = qw( MAB::File );
use MAB::Field;
use MAB::Record qw( LEADER_LEN );
use XML::Parser;
use XML::Writer;


# Die verbleibenden MAB2-Steuerzeichen „Nichtsortierzeichen“, „Teilfeldtrennzeichen“ und 
# „Stichwortzeichen“ werden durch die Tags <ns></ns> (Nichtsortierzeichen), <stw></stw> 
# (Stichwortzeichen) und das leere Element <tf/> (Teilfeldtrennzeichen) ersetzt
# MAB2 Zeichen/Bedeutung MAB2  Unicode Zeichen/Bedeutung ISO/IEC 10646 / Unicode 
# 88  Nicht-Sortier-Zeichen, Beginn  0098  <control> / START OF STRING   3) 
# 89  Nicht-Sortier-Zeichen, Ende  009C  <control> / STRING TERMINATOR    3) 
# B6  Doppelkreuz  2021  DOUBLE DAGGER      6)
# 7B  geschweifte Klammer auf (Stichwort-Beginn)  007B  LEFT CURLY BRACKET 
# 7D  geschweifte Klammer zu (Stichwort-Ende)  007D  RIGHT CURLY BRACKET 
# 6) zu B6 
# In MAB wird B6 als Strukturelement "Teilfeldtrennzeichen" verwendet.

# Nicht-Sortier-Zeichen <ns></ns>
use constant START_OF_STRING   => "\x98";
use constant STRING_TERMINATOR => "\x9c";

# Stichwort <stw></stw>
use constant LEFT_CURLY_BRACKET  => "\x7b";
use constant RIGHT_CURLY_BRACKET => "\x7d";

# Teilfeldtrennzeichen <tf/>
use constant DOUBLE_DAGGER => "\x87";

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module provides functions for serializing and deserializing MABxml data.

=head1 SYNOPSIS

    use MAB::File::MABxml;

    my $file = MAB::File::MABxml->in( $filename );

    while ( my $mab = $file->next() ) {
        # Do something
    }
    $file->close();
    undef $file;

=head1 METHODS

=cut

my %stack = (
    record         => undef,
    field          => undef,
    tag            => undef,
    ind            => undef,
    data           => undef,
    subfields      => undef,
    subfield_code  => undef,
    subfield_value => undef,
);

sub _next {
    my $self = shift;
    my $fh   = $self->{fh};
    ## return undef at the end of the file
    return if eof($fh);

    ## get a chunk of xml for a record
    local $/ = '</datensatz>';
    my $xml = <$fh>;

    ## trim stuff before the start record element
    $xml =~ s/.*?(<datensatz.*?>)/$1/s;
    ## return undef if there isn't a good chunk of xml
    return if ( $xml !~ m|<datensatz.*?>.*?</datensatz>|s );

    ## return the chunk of xml
    return ($xml);
}

=head2 decode( $string )

Deserialize a MABxml record string to a MAB::Record object.

=cut

sub decode {
    my $text;
    my $location = '';
    my $self     = shift;
    if ( ref($self) =~ /^MAB::File/ ) {
        $location = 'in record ' . $self->{recnum};
        $text     = shift;
    }
    else {
        $location = 'in record 1';
        $text = $self =~ /MAB::File/ ? shift : $self;
    }
    my $parser = XML::Parser->new();
    $parser->setHandlers(
        Start => \&start_handler,
        Char  => \&text_handler,
        End   => \&end_handler,
    );
    $parser->parse($text);

    return $stack{record};
}

=head2 encode( $string )

Serialize a MAB2::Record object to a MABxml record string. 

=cut

sub encode {
    my $record;
    my $location = '';
    my $self     = shift;
    if ( ref($self) =~ /^MAB::File/ ) {
        $location = 'in record ' . $self->{recnum};
        $record   = shift;
    }
    else {
        $location = 'in record 1';
        $record = $self =~ /MAB::File/ ? shift : $self;
    }

    my $mabxml;
    my $mabxml_ref = \$mabxml;
    my $writer = XML::Writer->new( OUTPUT => $mabxml_ref );

    my $leader = $record->leader();
    $writer->startTag(
        "datensatz",
        "xmlns"      => "http://www.ddb.de/professionell/mabxml/mabxml-1.xsd",
        "typ"        => $record->record_type(),
        "status"     => $record->record_status(),
        "mabVersion" => "M2.0"
    );
    my @fields = $record->fields();
    foreach my $field (@fields) {

        if ( $field->data() ) {
            $writer->startTag(
                "feld",
                "nr"  => $field->tag(),
                "ind" => $field->indicator()
            );
            $writer->characters( $field->data() );
            $writer->endTag("feld");
        }
        else {
            $writer->startTag(
                "feld",
                "nr"  => $field->tag(),
                "ind" => $field->indicator()
            );
            my @subfields = $field->subfields();
            foreach my $subfield (@subfields) {
                $writer->startTag( "uf", "code" => ( keys %$subfield )[0] );
                $writer->characters( $subfield->{ ( keys %$subfield )[0] } );
                $writer->endTag("uf");
            }
            $writer->endTag("feld");
        }
    }
    $writer->endTag("datensatz");
    $writer->end();

    return $$mabxml_ref;
}

# XML handlers

sub start_handler {
    my ( $parser, $element, %attrs ) = @_;
    if ( $element eq 'uf' ) {
        $stack{subfield_code} = $attrs{code};
    }
    elsif ( $element eq 'feld' ) {
        $stack{tag} = $attrs{nr};
        $stack{ind} = $attrs{ind};
    }
    elsif ( $element eq 'datensatz' ) {
        $stack{record} = MAB::Record->new();
        $stack{record}->leader(
            ".....$attrs{status}$attrs{mabVersion}.............$attrs{typ}");
    }
    elsif ( $element eq 'tf' ) {
        if ( $stack{subfield_code} ){
            $stack{subfield_value} .= "\N{DOUBLE DAGGER}";
        }else{
            $stack{data} .= "\N{DOUBLE DAGGER}";
        }
    }
    elsif ( $element eq 'ns' ) {
        if ( $stack{subfield_code} ){
            $stack{subfield_value} .= "\N{START OF STRING}";
        }else{
            $stack{data} .= "\N{START OF STRING}";
        }
    }
    elsif ( $element eq 'stw' ) {
        if ( $stack{subfield_code} ){
            $stack{subfield_value} .= "\N{LEFT CURLY BRACKET}";
        }else{
            $stack{data} .= "\N{LEFT CURLY BRACKET}";
        }
    }
}

sub text_handler {
    my ( $parser, $text ) = @_;
    chomp($text);
    if ( defined $stack{subfield_code} ) {
        $stack{subfield_value} .= $text;
    }
    else {
        $stack{data} .= $text;
    }
}

sub end_handler {
    my ( $parser, $element ) = @_;
    if ( $element eq 'uf' ) {
        push( @{ $stack{subfields} },
            $stack{subfield_code}, $stack{subfield_value} );
        $stack{subfield_code}  = undef;
        $stack{subfield_value} = undef;
    }
    elsif ( $element eq 'feld' ) {
        if ( defined $stack{subfields} ) {
            $stack{field} =
              MAB::Field->new( $stack{tag}, $stack{ind},
                @{ $stack{subfields} } );
            $stack{record}->append_fields( $stack{field} );
        }
        else {
            $stack{field} =
              MAB::Field->new( $stack{tag}, $stack{ind}, $stack{data} );
            $stack{record}->append_fields( $stack{field} );
        }
        $stack{field}     = undef;
        $stack{tag}       = undef;
        $stack{ind}       = undef;
        $stack{data}      = undef;
        $stack{subfields} = undef;
    }
    elsif ( $element eq 'ns' ) {
        if ( $stack{subfield_code} ){
            $stack{subfield_value} .= "\N{STRING TERMINATOR}";
        }else{
            $stack{data} .= "\N{STRING TERMINATOR}";
        }
    }
    elsif ( $element eq 'stw' ) {
        if ( $stack{subfield_code} ){
            $stack{subfield_value} .= "\N{RIGHT CURLY BRACKET}";
        }else{
            $stack{data} .= "\N{RIGHT CURLY BRACKET}";
        }
    }
}

1;
__END__

=head1 RELATED MODULES

L<MAB::Batch>, L<MAB::File>, L<MAB::File::MAB2>, L<MAB::File::MABjson>, L<MAB::Record>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MAB::File::MABxml


=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
