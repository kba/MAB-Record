package MAB::File::MAB2;

=head1 NAME

MAB::File::MAB2 - MAB2-specific file handling

=cut

use strict;
use warnings;
use integer;
use bytes;
use vars qw( $ERROR );
use MAB::File;
use vars qw( @ISA ); @ISA = qw( MAB::File );
use MAB::Record qw( LEADER_LEN );

use constant SUBFIELD_INDICATOR     => "\x1F";
use constant END_OF_FIELD           => "\x1E";
use constant END_OF_RECORD          => "\x1D";

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module contains a parser for MAB2 files.

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
    my $fh = $self->{fh};

    my $reclen;
    return if eof($fh);

    local $/ = END_OF_RECORD;
    my $mab = <$fh>;

    # remove illegal garbage that sometimes occurs between records
    $mab =~ s/^[ \x00\x0a\x0d\x1a]+//;

    return $mab;
}

=head2 decode( $string )

Constructor for handling data from a MAB2 file.  This function takes care of
all the tag directory parsing & mangling.

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
        $location = 'in record '.$self->{recnum};
        $text = shift;
    } else {
        $location = 'in record 1';
        $text = $self=~/MAB::File/ ? shift : $self;
    }

    # ok this the empty shell we will fill
    my $mab = MAB::Record->new();

    my $reclen = substr( $text, 0, 5 );
    # Check for an all-numeric record length
    if($text =~ /^(\d{5})/){
        my $realLength = bytes::length( $text );
        ($reclen == $realLength) 
            or $mab->_warn( "Invalid record length $location: Leader says $reclen " . "bytes but it's actually $realLength" );
    }else{
        $mab->_warn( "Record length \"", substr( $text, 0, 5 ), "\" is not numeric $location" );
    }

    (substr($text, -1, 1) eq END_OF_RECORD)
        or $mab->_warn( "Invalid record terminator $location" );

    $mab->leader( substr( $text, 0, LEADER_LEN ) );
 
    my @fields = split( END_OF_FIELD, substr( $text, LEADER_LEN, -1 ) );
    foreach my $field (@fields) {
        my $tagno = substr( $field, 0, 3 );
        my $ind = substr( $field, 3, 1 );
        my $tagdata = substr( $field, 4 );
        
        ($tagno =~ /^[0-9]{3}$/) or $mab->_warn( "Invalid tag at $location: \"$tagno$ind\"" );
        ($ind =~ /^[a-z\s]$/) or $mab->_warn( "Invalid ind at $location: \"$tagno$ind\"" );
        
        # check if tagdata contains subfields
        if ( $tagdata =~ SUBFIELD_INDICATOR ) {
        
            # check if tagdata starts with a SUBFIELD_INDICATOR 
            (substr( $tagdata, 0 , 1 ) eq SUBFIELD_INDICATOR) or $mab->_warn( "Invalid subfield structure at $location: \"$tagno$ind\"" );
            my @subfields = split( SUBFIELD_INDICATOR, substr( $tagdata, 1 ) ); 
            my @subfield_data = map { substr($_, 0, 1), substr($_, 1) } @subfields;
            if ( !@subfield_data ) {
                $mab->_warn( "no subfield data found at $location: \"$tagno$ind\"" );
                # next;
            }            
            $mab->append_fields( MAB::Field->new( $tagno, $ind,  @subfield_data ) );       
        } else {
            $mab->append_fields( MAB::Field->new( $tagno, $ind,  $tagdata ) );
        }
    }   
    return $mab;
}

1;
__END__

=head1 RELATED MODULES

L<MAB::Record>, L<MAB::Field>, L<MAB::File>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MAB::File::MAB2

=head1 ACKNOWLEDGEMENTS

This program is inspired by and designed after L<MARC::File::USMARC>.  

=head1 TODO

Implement a optional filter function. See L<MARC::File::USMARC>

=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.