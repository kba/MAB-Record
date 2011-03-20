package MAB::File;

=head1 NAME

MAB::File - Base class for files of MAB records

=cut

use strict;
use integer;
use vars qw( $ERROR );

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module can be used to parse a MAB2 file. The conrete parsers is implemented in L<MAB::File::MAB2>.

=head1 SYNOPSIS

    use MAB::File::MAB2;

    my $file = MAB::File::MAB2->in( $filename );

    while ( my $mab = $file->next() ) {
        # Do something
    }
    $file->close();
    undef $file;

=head1 METHODS

=head2 in()

Opens a file for import. Ordinarily you will use C<MAB::File::MAB2>
 to do this.

    my $file = MAB::File::MAB2->in( 'file.mab' );

Returns a C<MAB::File> object, or dies on failure.

Optionally you can also pass in a filehandle.

    my $handle = IO::File->new( 'gunzip -c file.mab.gz |' );
    my $file = MAB::File::MAB2->in( $handle );

=cut

sub in {
    my $class = shift;
    my $arg = shift;
    my ( $filename, $fh );

    ## if a valid filehandle was passed in
    my $ishandle = do { no strict; defined fileno($arg); };
    if ( $ishandle ) {
        $filename = scalar( $arg );
        $fh = $arg;
    }

    ## otherwise check if it's a filename, and
    ## return undef if we weren't able to open it
    else {
        $filename = $arg;
        $fh = eval { local *FH; open( FH, $arg ) or die; *FH{IO}; };
        if ( $@ ) {
            die "Couldn't open file $filename: $@";
            return;
        }
    }

    my $self = {
        filename    => $filename,
        fh          => $fh,
        recnum      => 0,
        warnings    => [],
    };

    return( bless $self, $class );

} # new()

=head2 next()

Reads the next record from the file handle passed in. Returns a MAB::Record reference, or C<undef> on error.

=cut

sub next {
    my $self = shift;
    $self->{recnum}++;
    my $rec = $self->_next() or return;
    my $rec_decoded = $self->decode($rec, @_);
	my @warnings = @{ $rec_decoded->{_warnings} };
	if (@warnings) {
		push(@{ $self->{warnings} }, @warnings);
	}
	return($rec_decoded);
}

=head2 skip()

Skips over the next record in the file.

Returns 1 or undef.

=cut

sub skip {
    my $self = shift;
    my $rec = $self->_next() or return;
    return 1;
}

=head2 warnings()

Simlilar to the methods in L<MAB::Record> and L<MAB::Batch>,
C<warnings()> will return any warnings that have accumulated while
processing this file; and as a side-effect will clear the warnings buffer.

=cut

sub warnings {
    my $self = shift;
    my @warnings = @{ $self->{warnings} };
    $self->{warnings} = [];
    return(@warnings);
}

=head2 close()

Closes the file, both from the object's point of view, and the actual file.

=cut

sub close {
    my $self = shift;
    close( $self->{fh} );
    delete $self->{fh};
    delete $self->{filename};
    return;
}

sub _unimplemented() {
    my $self = shift;
    my $method = shift;
    warn "Method $method must be overridden";
}

=head2 write()

Writes a record to the output file.  This method must be overridden
in your subclass.

=head2 decode()

Decodes a record into a MAB2 format.  This method must be overridden
in your subclass.

=cut

sub write   { $_[0]->_unimplemented("write"); }
sub decode  { $_[0]->_unimplemented("decode"); }

# NOTE: _warn must be called as an object method

sub _warn {
    my ($self,$warning) = @_;
    push( @{ $self->{warnings} }, "$warning in record ".$self->{recnum} );
    return( $self );
}

1;

__END__

=head1 RELATED MODULES

L<MAB::File::MAB2>, L<MAB::Batch>, L<MAB::Record>.

=cut

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MAB::File

=head1 ACKNOWLEDGEMENTS

This program is inspired by and designed after L<MARC::File>.  

=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut