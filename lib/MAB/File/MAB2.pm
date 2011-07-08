package MAB::File::MAB2;

=head1 NAME

MAB::File::MAB2 - Serialization & Deserialization of MAB2 data

=cut

use v5.12;

use utf8;
use strict;
use autodie;
use warnings; 
use warnings    qw< FATAL  utf8     >;
use charnames   qw< :full >;
use feature     qw< unicode_strings >;

use Carp                qw< carp croak confess cluck >;
use Encode              qw< >;

use vars qw< @ISA $ERROR >;
use MAB::File;
@ISA = qw< MAB::File >;
use MAB::Record qw< LEADER_LEN >;

use constant SUBFIELD_INDICATOR => "\N{INFORMATION SEPARATOR ONE}";
use constant END_OF_FIELD       => "\N{INFORMATION SEPARATOR TWO}";
use constant END_OF_RECORD      => "\N{INFORMATION SEPARATOR THREE}";

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module provides functions for serializing and deserializing MAB2 data.

=head1 SYNOPSIS

    use MAB::File::MAB2;

    my $file = MAB::File::MAB2->in( $filename );

    while ( my $mab = $file->next() ) {
        # Do something
    }
    $file->close();
    undef $file;

=head1 METHODS

=cut

sub _next {
    my $self = shift;
    my $fh   = $self->{fh};

    my $reclen;
    return if eof($fh);

    local $/ = END_OF_RECORD;
    my $mab = <$fh>;

    # remove illegal garbage that sometimes occurs between records
    $mab =~ s/^[ \x00\x0a\x0d\x1a]+//;

    return $mab;
}

=head2 decode( $string )

Deserialize a MAB2 record string to a MAB::Record object.

Any warnings can be checked in the C<warnings()> function.

=cut

sub decode {

    my $text;
    my $location = '';

    ## decode can be called in a variety of ways
    ## $object->decode( $string )
    ## MAB::File::MAB2->decode( $string )
    ## MAB::File::MAB2::decode( $string )
    ## this bit of code covers all three

    my $self = shift;
    if ( ref($self) =~ /^MAB::File/ ) {
        $location = 'in record ' . $self->{recnum};
        $text     = shift;
    }
    else {
        $location = 'in record 1';
        $text = $self =~ /MAB::File/ ? shift : $self;
    }

    # create a new MAB::Record object
    my $mab = MAB::Record->new();

    my $reclen = substr( $text, 0, 5 );

    # check for an all-numeric record length
    if ( $text =~ /^(\d{5})/ ) {
        my $realLength = bytes::length($text);
        ( $reclen == $realLength )
          or
          $mab->_warn( "Invalid record length $location: Leader says $reclen "
              . "bytes but it's actually $realLength" );
    }
    else {
        $mab->_warn(
            "Record length \"",
            substr( $text, 0, 5 ),
            "\" is not numeric $location"
        );
    }

    # check for record terminator
    ( substr( $text, -1, 1 ) eq END_OF_RECORD )
      or $mab->_warn("Invalid record terminator $location");

    # set leader in MAB::Record object
    $mab->leader( substr( $text, 0, LEADER_LEN ) );

    # get record fields
    my @fields = split( END_OF_FIELD, substr( $text, LEADER_LEN, -1 ) );
    foreach my $field (@fields) {
        my $tagno = substr( $field, 0, 3 );
        my $ind   = substr( $field, 3, 1 );
        my $tagdata = substr( $field, 4 );

        # check for a 3-digit numeric tag
        ( $tagno =~ /^[0-9]{3}$/ )
          or $mab->_warn("Invalid tag at $location: \"$tagno$ind\"");

        # check if indicator is an single alphabetic character
        ( $ind =~ /^[a-z\s]$/ )
          or $mab->_warn("Invalid ind at $location: \"$tagno$ind\"");

        # check if tagdata contains subfields
        if ( $tagdata =~ SUBFIELD_INDICATOR ) {

            # check if tagdata starts with a SUBFIELD_INDICATOR
            ( substr( $tagdata, 0, 1 ) eq SUBFIELD_INDICATOR )
              or $mab->_warn(
                "Invalid subfield structure at $location: \"$tagno$ind\"");
            my @subfields = split( SUBFIELD_INDICATOR, substr( $tagdata, 1 ) );
            my @subfield_data =
              map { substr( $_, 0, 1 ), substr( $_, 1 ) } @subfields;
            if ( !@subfield_data ) {
                $mab->_warn(
                    "no subfield data found at $location: \"$tagno$ind\"");

                # next;
            }
            $mab->append_fields(
                MAB::Field->new( $tagno, $ind, @subfield_data ) );
        }
        else {
            $mab->append_fields( MAB::Field->new( $tagno, $ind, $tagdata ) );
        }
    }
    return $mab;
}

=head2 encode( $record )

Serialize a MAB2::Record object to a MAB2 record string. 

Any warnings can be checked in the C<warnings()> function.

=cut

sub encode {

    my $record;
    my $location = '';

    ## decode can be called in a variety of ways
    ## $object->decode( $mab2_record_object )
    ## MAB::File::MAB2->decode( $mab2_record_object )
    ## MAB::File::MAB2::decode( $mab2_record_object )
    ## this bit of code covers all three

    my $self = shift;
    if ( ref($self) =~ /^MAB::File/ ) {
        $location = 'in record ' . $self->{recnum};
        $record   = shift;
    }
    else {
        $location = 'in record 1';
        $record = $self =~ /MAB::File/ ? shift : $self;
    }
    my $mab2   = $record->leader();
    my @fields = $record->fields;
    foreach my $field (@fields) {
        if ( $field->data() ) {
            $mab2 .=
                $field->tag()
              . $field->indicator()
              . $field->data()
              . END_OF_FIELD;
        }
        else {
            $mab2 .= $field->tag() . $field->indicator();
            my @subfields = $field->subfields();
            foreach my $subfield (@subfields) {
                $mab2 .=
                    SUBFIELD_INDICATOR
                  . ( keys %$subfield )[0]
                  . $subfield->{ ( keys %$subfield )[0] };
            }
            $mab2 .= END_OF_FIELD;
        }
    }
    $mab2 .= END_OF_RECORD;
    return $mab2;
}

1;
__END__

=head1 RELATED MODULES

L<MAB::Batch>, L<MAB::File>, L<MAB::File::MABxml>, L<MAB::File::MABjson>, L<MAB::Record>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MAB::File::MAB2

=head1 ACKNOWLEDGEMENTS

This program is inspired by and designed after L<MARC::File::USMARC>.  

=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
