package MAB::Field;

=head1 NAME

MAB::Field - Perl extension for handling MAB fields

=cut

use strict;
use warnings;
use integer;
use Carp;

use constant SUBFIELD_INDICATOR => "\x1F";
use constant END_OF_FIELD       => "\x1E";

use vars qw( $ERROR );

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

Defines MAB2 fields for use in the L<MAB::Record> module.


=head1 SYNOPSIS

  use MAB::Field;

  my $field1 = MAB::Field->new( 542, 'a', '1940-5758');
  my $field2 = MAB::Field->new( 655, ' ', 
       'u' => 'http://journal.code4lib.org/',
	   'x' => 'Verlag',
       'z' => 'kostenfrei'
  );


=head1 CONSTRUCTORS

=head2 new()

The constructor, which will return a MAB::Field object. Typically you will
pass in the tag number, indicator and tag data. For example:

  my $field = MAB::Field->new( 542, 'a', '0032-3500');

Or if you want to add a field with subfields:

  my $field = MAB::Field->new( 655, ' ', 
       'u' => 'http://journal.code4lib.org/',
	   'x' => 'Verlag',
       'z' => 'kostenfrei'
  );

=cut

sub new {
    my $class = shift;
    $class = $class;

	# only three-digit tags allowed
    my $tagno = shift;
    ($tagno =~ /^[0-9]{3}$/)
        or croak( "Tag \"$tagno\" is not a valid tag." );

    my $ind = shift;
    if ($ind !~ /^[\sa-z]$/){
		croak( "Indicator \"$ind\" at field \"$tagno\" is not a valid indicator" ) unless ($ind eq "");
		$ind = " ";
	}
		
    my $self = bless {
        _tag => $tagno,
		_ind => $ind,
        _warnings => [],
    }, $class;

	(@_ >= 1)
		or croak( "Field $tagno must have at least some data or one subfield" );
	if (@_ == 1){
		$self->{_data} = shift;
	}else{
		$self->{_subfields} = [@_];
	}

    return $self;
} # new()


=head2 tag()

Returns the three digit tag for the field.

=cut

sub tag {
    my $self = shift;
    return $self->{_tag};
}

=head2 indicator()

Returns the indicator for that field.

=cut

sub indicator {
    my $self = shift;
	return $self->{_ind};
}

=head2 subfield( $subfield_code )

When called in a scalar context returns the text from the first subfield
matching the subfield code.

    my $subfield = $field->subfield( 'a' );

Or if there might be more than one you can get all of them by
calling in a list context:

    my @subfields = $field->subfield( 'a' );

If no matching subfields are found, C<undef> is returned in a scalar context
and an empty list in a list context.

=cut

sub subfield {
    my $self = shift;
    my $code_wanted = shift;

    croak( "Field does not have any subfields, try data()" ) unless $self->{_subfields};

    my @data = @{$self->{_subfields}};
    my @found;
    while ( defined( my $code = shift @data ) ) {
        if ( $code eq $code_wanted ) {
            push( @found, shift @data );
        } else {
            shift @data;
        }
    }
    if ( wantarray() ) { return @found; }
    return( $found[0] );
}

=head2 subfields()

Returns all the subfields in the field.  What's returned is a list of
hash refs.

For example, this might be the subfields from a 655 field:

        (
          { 'u' => 'http://journal.code4lib.org/' },
          { 'x' => 'Verlag' },
          { 'z' => 'kostenfrei' },
        )

=cut

sub subfields {
    my $self = shift;

    croak( "Field does not have any subfields, try data()" ) unless $self->{_subfields};

    my @list;
    my @data = @{$self->{_subfields}};
    while ( defined( my $code = shift @data ) ) {
        push( @list, {$code => shift @data} );
    }
    return @list;
}

=head2 data()

Returns the data part of the field.

=cut

sub data {
    my $self = shift;

    croak( "Field does not have any data, try subfield()" ) unless $self->{_data};

    $self->{_data} = $_[0] if @_;

    return $self->{_data};
}

=head2 add_subfields(code,text[,code,text ...])

Adds subfields to the end of the subfield list.

    $field->add_subfields( 'c' => '1985' );

Returns the number of subfields added, or C<undef> if there was an error.

=cut

sub add_subfields {
    my $self = shift;

    push( @{$self->{_subfields}}, @_ );
    return @_/2;
}

=head2 as_string( $subfields )

Returns a string of all subfields run together.  A space is added to
the result between each subfield.  The tag number and subfield
character are not included.

Subfields appear in the output string in the order in which they
occur in the field.

If C<$subfields> is specified, then only those subfields will be included.

  my $field = MAB::Field->new( '655', ' ', 
                'u' => 'http://journal.code4lib.org/',
                'x' => 'Verlag',
                'z' => 'kostenfrei'
                );
  print $field->as_string( 'ux' ); # Only those two subfields
  # prints 'http://journal.code4lib.org/ Verlag'.

=cut

sub as_string() {
    my $self = shift;
    my $subfields = shift;

    if ( $self->{_data} ) {
        return $self->{_data};
    }

    my @subs;

    my $subs = $self->{_subfields};
    my $nfields = @$subs / 2;
    for my $i ( 1..$nfields ) {
        my $offset = ($i-1)*2;
        my $code = $subs->[$offset];
        my $text = $subs->[$offset+1];
        push( @subs, $text ) if !$subfields || $code =~ /^[$subfields]$/;
    } # for

    return join( " ", @subs );
}

=head2 warnings()

Returns the warnings that were created when the record was read.

=cut

sub warnings() {
    my $self = shift;

    return @{$self->{_warnings}};
}

# NOTE: _warn is an object method
sub _warn {
    my $self = shift;

    push( @{$self->{_warnings}}, join( "", @_ ) );
}

sub _gripe {
    $ERROR = join( "", @_ );

    warn $ERROR;

    return;
}

1;

__END__

=head1 RELATED MODULES

L<MAB::Record>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MAB::Field

=head1 ACKNOWLEDGEMENTS

This program is inspired by and designed after L<MARC::Field>.  

=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut