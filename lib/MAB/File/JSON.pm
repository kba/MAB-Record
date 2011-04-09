package MAB::File::JSON;

=head1 NAME

MAB::File::JSON - Module for serializing MAB2::Record objects into JSON

=cut

use strict;
use warnings;

use MAB::Record;
use Mojo::JSON;

=head1 VERSION

Version 0.01 

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module provides a function for serializing MAB2::Record objects into a JSON hash structure.

=head1 SYNOPSIS

    use MAB::Record;
    use MAB::File::JSON;
    
    my $record = MAB::Record::new_from_mab2( $mab_record );
    my $json_string = MAB::File::JSON->encode( $record );

=head1 METHODS

=cut

=head2 encode( $record )

Method for for serializing MAB2::Record objects into a JSON hash structure.

=cut

sub encode {

my $record = shift;
my %record_hash = (
    'leader' => $record->leader(),
    'fields' => [],
);

my @fields = $record->fields;
foreach my $field ( @fields ){
    if ( $field->data() ){
        push( @{$record_hash{fields}}, { tag => $field->tag(), ind => $field->indicator(), data => $field->data()} );
    }else{
        push( @{$record_hash{fields}}, { tag => $field->tag(), ind => $field->indicator(), subfields => [$field->subfields()]} );
    }
}

my $json        = Mojo::JSON->new;
my $json_string = $json->encode( { %record_hash } );
return $json_string;

}

1;
__END__

=head1 RELATED MODULES

L<MAB::Record>, L<MAB::Field>, L<MAB::File>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MAB::File::JSON

=head1 ACKNOWLEDGEMENTS

This program is inspired by the proposal L<http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/> for the serialization of MARC records in JSON.

=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.