package MAB::File::MABjson;

=head1 NAME

MAB::File::MABjson - Serialization & Deserialization of MABjson data

=cut

use strict;
use warnings;

use Encode qw();
use MAB::Record;
use Mojo::JSON;

=head1 VERSION

Version 0.01 

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

Deserialize a MABjson record to a MAB::Record object.

=cut

sub decode {

    my $string = shift;

    my $json   = Mojo::JSON->new;
    my $hash   = $json->Mojo::JSON::decode($string);
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

    my $record      = shift;
    
    my %record_hash = (
        'leader' => $record->leader(),
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

    # return $json_string
    # double-encoding workaround, fix filehandling and encoding
    my $tmp = Encode::decode( "utf8", $json_string );
    return $tmp;

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
