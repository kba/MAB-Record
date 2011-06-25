package MAB::Record;

=head1 NAME

MAB::Record - Perl module for handling MAB2, MABxml and MABjson records

=cut

use strict;
use warnings;
use integer;
use Carp qw(croak);
use vars qw( $ERROR );

use MAB::Field;

use Exporter;
use vars qw( @ISA @EXPORTS @EXPORT_OK );
@ISA       = qw( Exporter );
@EXPORTS   = qw();
@EXPORT_OK = qw( LEADER_LEN );

use vars qw( $DEBUG );
$DEBUG = 0;

use constant LEADER_LEN => 24;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

Module for handling B<MAB2> (Maschinelles Austauschformat für Bibliotheken), 
MABxml and MABjson records as objects. The package supports the deserialization
and serialization of MAB2, MABxml and MABjson records. The decoding of records
is handled by L<MAB::File::MAB2>, L<MAB::File::MABxml> and L<MAB::File::MABjson>.
For handling of files with multiple records use L<MAB::File> or L<MAB::Batch>.

=head1 SYNOPSIS

    use MAB::Record;

    # read a record from a string
    my $record = MAB::Record::new_from_mab2($mab_record);
    
    # get all MAB::Field objects from a record
    my @fields = $record->fields;
    
    # get a specific field
    my $field = $record->field('311');
    
    # get a specific field with a specific indiactor
    my $field = $record->field('025', 'z');
    
    # get a specific subfiled from a record
    my $subfield = $record->subfield('655', ' ', 'u');
    

=head1 CONSTRUCTORS

=head2 new()

Base constructor for the class. It just returns a completely empty record.
To get real data, you'll need to populate it with fields, or use one of
the MAB::File::* modules to read from a file.

=cut

sub new {
    my $class = shift;
    my $self  = {
        _leader   => ' ' x 24,
        _fields   => [],
        _warnings => [],
    };
    return bless $self, $class;
}    # new()

=head2 new_from_mab2( $mab2_record )

This is a wrapper around C<MAB::File::MAB2::decode()>.

=cut

sub new_from_mab2 {
    my $blob = shift;
    $blob = shift if ( ref($blob) || ( $blob eq "MAB::Record" ) );

    require MAB::File::MAB2;

    return MAB::File::MAB2::decode( $blob, @_ );
}

=head2 new_from_mabxml( $mabxml_record )

This is a wrapper around C<MAB::File::MABxml::decode()>.

=cut

sub new_from_mabxml {
    my $blob = shift;
    $blob = shift if ( ref($blob) || ( $blob eq "MAB::Record" ) );

    require MAB::File::MABxml;

    return MAB::File::MABxml::decode( $blob, @_ );
}

=head2 new_from_mabjson( $mabjson_record )

This is a wrapper around C<MAB::File::MABjson::decode()>.

=cut

sub new_from_mabjson {
    my $blob = shift;
    $blob = shift if ( ref($blob) || ( $blob eq "MAB::Record" ) );

    require MAB::File::MABjson;

    return MAB::File::MABjson::decode( $blob, @_ );
}

=head1 COMMON FIELD RETRIEVAL METHODS

Some methods for commonly-retrieved MAB fields. Please note that they
return strings, not MAB::Field objects. They return empty strings if 
the appropriate field or subfield is not found. 

=head2 title()

Returns the title from the 331 tag.

=cut

sub title() {
    my $self = shift;

    my $field = $self->field(331);
    return $field ? $field->as_string : "";
}

=head2 record_id()

Returns the record id from the 001 tag.

=cut

sub record_id() {
    my $self = shift;

    my $field = $self->field('001');
    return $field ? $field->as_string : "";
}

=head2 record_type()

Returns the record type.

=cut

sub record_type() {
    my $self = shift;

    my $record_type = substr( $self->{_leader}, -1 );
    return $record_type ? $record_type : "";
}

=head2 record_length()

Returns the record length defined in the record leader.

=cut

sub record_length() {
    my $self = shift;

    my $record_type = substr( $self->{_leader}, 0, 5 );
    return $record_type ? $record_type : "";
}

=head2 record_status()

Returns the status of the record.

=cut

sub record_status() {
    my $self = shift;

    my $record_type = substr( $self->{_leader}, 5, 1 );
    return $record_type ? $record_type : "";
}

=head2 issn()

Returns the ISSN from the 542a tag.

=cut

sub issn() {
    my $self = shift;

    my $field = $self->field( '542', 'a' );
    return $field ? $field->as_string : "";
}

=head1 FIELD & SUBFIELD ACCESS METHODS

=head2 fields()

Returns a list of all the fields in the record. The list contains
a MAB::Field object for each field in the record.

=cut

sub fields() {
    my $self = shift;
    return @{ $self->{_fields} };
}

=head2 field( { $field }+ [, $indicator ] )

Returns a list of fileds that match the field specifier, or an empty
list if nothing matched. In scalar context, returns the first
matching tag, or undef if nothing matched.

The field specifier can be a simple number (i.e. "245") or  a regular 
expressions (i.e. "6.." or "65[]").  If the last parameter is a 
single small alphabetic or space character, it is used as a indicator.

  my $field  = $record->field("001");
  my $field  = $record->field("025", "z");
  my @fields = $record->field("65.");
  my @fields = $record->field("65[23]");

=cut

my %field_regex;

sub field {
    my $self  = shift;
    my @specs = @_;
    my @list  = ();
    if ( $specs[-1] =~ /^[\sa-z]$/xms ) {
        my $ind = pop(@specs);
        for my $tag (@specs) {
            my $regex = $field_regex{$tag};

            # Compile & stash it if necessary
            if ( not defined $regex ) {
                $regex = qr/^$tag$/;
                $field_regex{$tag} = $regex;
            }    # not defined

            for my $maybe ( $self->fields ) {
                if ( $maybe->tag =~ $regex && $maybe->indicator =~ $ind ) {
                    return $maybe unless wantarray;

                    push( @list, $maybe );
                }    # if
            }    # for $maybe
        }    # for $tag
    }
    else {
        for my $tag (@specs) {
            my $regex = $field_regex{$tag};

            # Compile & stash it if necessary
            if ( not defined $regex ) {
                $regex = qr/^$tag$/;
                $field_regex{$tag} = $regex;
            }    # not defined

            for my $maybe ( $self->fields ) {
                if ( $maybe->tag =~ $regex ) {
                    return $maybe unless wantarray;

                    push( @list, $maybe );
                }    # if
            }    # for $maybe
        }    # for $tag
    }

    return unless wantarray;
    return @list;
}

=head2 subfield( $tag, $indicator, $subfield )

Shortcut method for getting just specific subfields for a tag and 
indicator. Returns a list of subfields that match the subfield 
specifier, or an empty list if nothing matched. In scalar context, 
returns the first matching tag, or undef if nothing matched.

  # in scalar context
  my $url = $mab->subfield('655', ' ', 'u');
  
  # in list context
  my @urls = $mab->subfield('655', ' ', 'u');;

=cut

sub subfield {
    my $self     = shift;
    my $tag      = shift;
    my $ind      = shift;
    my $subfield = shift;

    my @fields = $self->field( $tag, $ind ) or return;

    my @list = ();
    foreach my $field (@fields) {
        if ( $field->subfield($subfield) ) {
            return $field->subfield($subfield) unless wantarray;
            push( @list, $field->subfield($subfield) );
        }
    }
    return unless wantarray;
    return @list;
}    # subfield()

=for internal

=cut

sub _all_parms_are_fields {
    for (@_) {
        return 0 unless ref($_) eq 'MAB::Field';
    }
    return 1;
}

=head2 append_fields( @fields )

Appends the field specified by C<$field> to the end of the record.
C<@fields> need to be MAB::Field objects.

    my $field = MAB::Field->new('655',' ', 'u' => 'http://journal.code4lib.org/');
    $record->append_fields($field);

Returns the number of fields appended.

=cut

sub append_fields {
    my $self = shift;

    _all_parms_are_fields(@_) or croak('Arguments must be MAB::Field objects');

    push( @{ $self->{_fields} }, @_ );
    return scalar @_;
}

=head2 insert_fields_before( $before_field, @new_fields )

Inserts the field specified by C<$new_field> before the field 
C<$before_field>. Returns the number of fields inserted, or undef
on failures. Both C<$before_field> and all C<@new_fields> need to 
be MAB::Field objects. If they are not an exception will be thrown.

    my $before_field = $record->field( '655' );
    my $new_field = MAB::Field->new( '653', ' ', 'a' => 'Online Ressource' );
    $record->insert_fields_before( $before_field, $new_field );

=cut

sub insert_fields_before {
    my $self = shift;

    _all_parms_are_fields(@_)
      or croak('All arguments must be MAB::Field objects');

    my ( $before, @new ) = @_;

    ## find position of $before
    my $fields = $self->{_fields};
    my $pos    = 0;
    foreach my $f (@$fields) {
        last if ( $f == $before );
        $pos++;
    }

    ## insert before $before
    if ( $pos >= @$fields ) {
        $self->_warn("Couldn't find field to insert before");
        return;
    }
    splice( @$fields, $pos, 0, @new );
    return scalar @new;

}

=head2 insert_fields_after( $after_field, @new_fields )

Identical to C<insert_fields_before()>, but fields are added after
C<$after_field>. Remember, C<$after_field> and any new fields must be
valid MAB::Field objects or else an exception will be thrown.

=cut

sub insert_fields_after {
    my $self = shift;

    _all_parms_are_fields(@_)
      or croak('All arguments must be MAB::Field objects');
    my ( $after, @new ) = @_;

    ## find position of $after
    my $fields = $self->{_fields};
    my $pos    = 0;
    foreach my $f (@$fields) {
        last if ( $f == $after );
        $pos++;
    }

    ## insert after $after
    if ( $pos + 1 > @$fields ) {
        $self->_warn("Couldn't find field to insert after");
        return;
    }
    splice( @$fields, $pos + 1, 0, @new );
    return scalar @new;
}

=head2 insert_fields_ordered( @new_fields )

Will insert fields in strictly numerical order. So a 008 will be filed
after a 001 field. See C<insert_grouped_field()> for an additional ordering.

=cut

sub insert_fields_ordered {
    my ( $self, @new ) = @_;

    _all_parms_are_fields(@new)
      or croak('All arguments must be MAB::Field objects');

    ## go through each new field
  NEW_FIELD: foreach my $newField (@new) {

        ## find location before which it should be inserted
      EXISTING_FIELD: foreach my $field ( @{ $self->{_fields} } ) {
            if ( $field->tag() >= $newField->tag() ) {
                $self->insert_fields_before( $field, $newField );
                next NEW_FIELD;
            }
        }

        ## if we fell through then this new field is higher than
        ## all the existing fields, so we append.
        $self->append_fields($newField);

    }
    return ( scalar(@new) );
}

=head2 leader()

Returns the leader for the record.  Sets the leader if I<text> is defined.
No error checking is done on the validity of the leader.

=cut

sub leader {
    my $self = shift;
    my $text = shift;

    if ( defined $text ) {
        ( length($text) eq 24 )
          or $self->_warn("Leader must be 24 bytes long");
        $self->{_leader} = $text;
    }    # set the leader

    return $self->{_leader};
}    # leader()

=head2 warnings()

Returns the warnings (as a list) that were created when the record was read.
These are things like "Invalid indicators converted to blanks".

    my @warnings = $record->warnings();

The warnings are items that you might be interested in, or might
not.  It depends on how stringently you're checking data.  If
you're doing some grunt data analysis, you probably don't care.

A side effect of calling warnings() is that the warning buffer will
be cleared.

=cut

sub warnings() {
    my $self     = shift;
    my @warnings = @{ $self->{_warnings} };
    $self->{_warnings} = [];
    return @warnings;
}

# NOTE: _warn is an object method
sub _warn {
    my $self = shift;
    push( @{ $self->{_warnings} }, join( "", @_ ) );
    return ($self);
}

# NOTE: _gripe is NOT an object method
sub _gripe {
    $ERROR = join( "", @_ );

    warn $ERROR;

    return;
}

1;

__END__

=head1 RELATED MODULES

L<MAB::Field>, L<MAB::Batch>, L<MAB::File>, L<MAB::File::MAB2>.

=head1 SEE ALSO

=over 4

=item * perl4lib (L<http://www.rice.edu/perl4lib/>)

A mailing list devoted to the use of Perl in libraries.

=item * MAB2 pages of the "Deutsche National Bibliothek" (L<http://www.d-nb.de/standardisierung/formate/mab.htm/>)

Documentation of MAB2 tags and subfields. German only.

=item * MABxml pages of the "Deutsche National Bibliothek" (L<http://www.d-nb.de/standardisierung/formate/mabxml.htm>)

Documentation of MABxml tags and subfields. German only.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-mab-record at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MAB-Record>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MAB::Record

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MAB-Record>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MAB-Record>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MAB-Record>

=item * Search CPAN

L<http://search.cpan.org/dist/MAB-Record/>

=back

=head1 ACKNOWLEDGEMENTS

This program is inspired by and designed after L<MARC::Record>.  

=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
