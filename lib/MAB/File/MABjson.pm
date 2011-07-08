package MAB::File::MABjson;

=head1 NAME

MAB::File::MABjson - Serialization & Deserialization of MABjson data

=cut

use v5.12;

use utf8;
use strict;
use autodie;
use warnings; 
use warnings    qw< FATAL  utf8     >;
use charnames   qw< :full >;
use feature     qw< unicode_strings >;

use Carp        qw< carp croak confess cluck >;
use Encode      qw< >;

use MAB::Record;
use Mojo::JSON;

=head1 VERSION

Version 0.02 

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module provides functions for serializing and deserializing MABjson data.

=head1 SYNOPSIS

    use MAB::Record;
    use MAB::File::MABjson;
    
    my $record = MAB::Record::new_from_mab2( $mab_record );
    my $json_string = MAB::File::MABjson->encode( $record );

=head1 METHODS

=head2 decode( $string )

Deserialize a MABjson record string to a MAB::Record object.

=cut

sub decode {
    my $self = shift;
    my $string = shift;
    # Mojo::JSON does not accept Perl strings. It accepts octets. 
    # So we have to encode Perl strings before passing them to JSON object
    $string = Encode::encode( "UTF-8", $string );
    my $json   = Mojo::JSON->new;
    my $hash   = $json->decode($string);
    my $record = MAB::Record->new();
    $record->leader( $hash->{leader} );
    foreach my $field ( @{ $hash->{fields} } ) {
        if ( defined $field->{subfields} ) {
            my @subfields = ();
            foreach my $subfield ( @{ $field->{subfields} } ) {
                push( @subfields,
                    ( keys %$subfield )[0],
                    $subfield->{ ( keys %$subfield )[0] } );
            }
            $record->append_fields(
                MAB::Field->new( $field->{tag}, $field->{ind}, @subfields ) );
        }
        else {
            $record->append_fields(
                MAB::Field->new( $field->{tag}, $field->{ind}, $field->{data} )
            );
        }
    }
    $record->append_fields();
    return $record;
}

=head2 encode( $record )

Serialize a MAB2::Record object to a MABjson record string. 

=cut

sub encode {
    my $self        = shift;
    my $record      = shift;
    my %record_hash = (
        'leader' => $record->MAB::Record::leader(),
        'fields' => [],
    );

    my @fields = $record->fields;
    foreach my $field (@fields) {
        if ( $field->data() ) {
            push(
                @{ $record_hash{fields} },
                {
                    tag  => $field->tag(),
                    ind  => $field->indicator(),
                    data => $field->data()
                }
            );
        }
        else {
            push(
                @{ $record_hash{fields} },
                {
                    tag       => $field->tag(),
                    ind       => $field->indicator(),
                    subfields => [ $field->subfields() ]
                }
            );
        }
    }

    my $json = Mojo::JSON->new;
    my $json_string = $json->encode( {%record_hash} );
    # Mojo::JSON->encode() returns UTF-8 string, but MAB::File::MABjson::encode() 
    # should return Perl string 
    $json_string = Encode::decode( "utf8", $json_string );
    return $json_string ;
}

1;

__END__

=head1 RELATED MODULES

L<MAB::Batch>, L<MAB::File>, L<MAB::File::MAB2>, L<MAB::File::MABxml>, L<MAB::Record>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MAB::File::MABjson

=head1 ACKNOWLEDGEMENTS

This program is inspired by the proposal 
L<http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/> 
for the serialization of MARC records in JSON.

=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
