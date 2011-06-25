package MAB::Batch;

=head1 NAME

MAB::Batch - Perl module for handling files of MAB::Record objects

=cut

use strict;
use warnings;
use integer;
use Carp qw( croak );

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module can be used to parse MAB2 files. The conrete parsers is implemented in L<MAB::File::MAB2>.

=head1 SYNOPSIS

MAB::Batch hides all the file handling of files of C<MAB::Record>s.
C<MAB::Record> still does the file I/O, but C<MAB::Batch> handles the
multiple-file aspects.

    use MAB::Batch;

    my $batch = MAB::Batch->new( 'MAB2', @files );
    while ( my $mab = $batch->next ) {
        print $mab->subfield(245,"a"), "\n";
    }

=head1 METHODS

=head2 new( $type, @files )

Create a C<MAB::Batch> object that will process C<@files>.

C<$type> must be "MAB2".
C<new()> returns a
new MAB::Batch object.

C<@files> can be a list of filenames:

    my $batch = MAB::Batch->new( 'MAB2', 'file1.mab', 'file2.mab' );

Your C<@files> may also contain filehandles. So if you've got a large
file that's gzipped you can open a pipe to F<gzip> and pass it in:

    my $fh = IO::File->new( 'gunzip -c mab.dat.gz |' );
    my $batch = MAB::Batch->new( 'MAB2', $fh );

And you can mix and match if you really want to:

    my $batch = MAB::Batch->new( 'MAB2', $fh, 'file1.mab' );

=cut

sub new {
    my $class = shift;
    my $type = shift;

    my $mabclass = ($type =~ /^MAB::File/) ? $type : "MAB::File::$type";

    eval "require $mabclass";
    croak $@ if $@;

    my @files = @_;

    my $self = {
        filestack   =>  \@files,
        filename    =>  undef,
        mabclass   =>  $mabclass,
        file        =>  undef,
        warnings    =>  [],
        'warn'      =>  1,
        strict      =>  1,
    };

    bless $self, $class;

    return $self;
} # new()


=head2 next()

Read the next record from that batch, and return it as a MAB::Record
object.  If the current file is at EOF, close it and open the next
one. C<next()> will return C<undef> when there is no more data to be
read from any batch files.

By default, C<next()> also will return C<undef> if an error is
encountered while reading from the batch. If not checked for this can
cause your iteration to terminate prematurely. To alter this behavior,
see C<strict_off()>. You can retrieve warning messages using the
C<warnings()> method.

Optionally you can pass in a filter function as a subroutine reference
if you are only interested in particular fields from the record. This
can boost performance.

=cut

sub next {
    my ( $self, $filter ) = @_;
    if ( $filter and ref($filter) ne 'CODE' ) {
        croak( "filter function in next() must be a subroutine reference" );
    }

    if ( $self->{file} ) {

        # get the next record
        my $rec = $self->{file}->next( $filter );

        # collect warnings from MAB::File::* object
        # we use the warnings() method here since MAB::Batch
        # hides access to MAB::File objects, and we don't
        # need to preserve the warnings buffer.
        my @warnings = $self->{file}->warnings();
        if ( @warnings ) {
            $self->warnings( @warnings );
            return if $self->{ strict };
        }

        if ($rec) {

            # collect warnings from the MAB::Record object
            # IMPORTANT: here we don't use warnings() but dig
            # into the the object to get at the warnings without
            # erasing the buffer. This is so a user can call 
            # warnings() on the MAB::Record object and get back
            # warnings for that specific record.
            
			#my @warnings = @{ $rec->{_warnings} };

            if (@warnings) {
                #$self->warnings( @warnings );
                return if $self->{ strict };
            }

            # return the MAB::Record object
            return($rec);

        }

    }

    # Get the next file off the stack, if there is one
    $self->{filename} = shift @{$self->{filestack}} or return;

    # Instantiate a filename for it
    my $mabclass = $self->{mabclass};
    $self->{file} = $mabclass->in( $self->{filename} ) or return;

    # call this method again now that we've got a file open
    return( $self->next( $filter ) );

}

=head2 strict_off()

If you would like C<MAB::Batch> to continue after it has encountered what
it believes to be bad MAB data then use this method to turn strict B<OFF>.
A call to C<strict_off()> always returns true (1).

C<strict_off()> can be handy when you don't care about the quality of your
MAB data, and just want to plow through it. For safety, C<MAB::Batch>
strict is B<ON> by default.

=cut

sub strict_off {
    my $self = shift;
    $self->{ strict } = 0;
    return(1);
}

=head2 strict_on()

The opposite of C<strict_off()>, and the default state. You shouldn't
have to use this method unless you've previously used C<strict_off()>, and
want it back on again.  When strict is B<ON> calls to next() will return
undef when an error is encountered while reading MAB data. strict_on()
always returns true (1).

=cut

sub strict_on {
    my $self = shift;
    $self->{ strict } = 1;
    return(1);
}

=head2 warnings()

Returns a list of warnings that have accumulated while processing a particular
batch file. As a side effect the warning buffer will be cleared.

    my @warnings = $batch->warnings();

This method is also used internally to set warnings, so you probably don't
want to be passing in anything as this will set warnings on your batch object.

C<warnings()> will return the empty list when there are no warnings.

=cut

sub warnings {
    my ($self,@new) = @_;
    if ( @new ) {
        push( @{ $self->{warnings} }, @new );
        print STDERR join( "\n", @new ) if $self->{'warn'};
    } else {
        my @old = @{ $self->{warnings} };
        $self->{warnings} = [];
        return(@old);
    }
}


=head2 warnings_off()

Turns off the default behavior of printing warnings to STDERR. However, even
with warnings off the messages can still be retrieved using the warnings()
method if you wish to check for them.

C<warnings_off()> always returns true (1).

=cut

sub warnings_off {
    my $self = shift;
    $self->{ 'warn' } = 0;

    return 1;
}

=head2 warnings_on()

Turns on warnings so that diagnostic information is printed to STDERR. This
is on by default so you shouldn't have to use it unless you've previously
turned off warnings using warnings_off().

warnings_on() always returns true (1).

=cut

sub warnings_on {
    my $self = shift;
    $self->{ 'warn' } = 1;
}

=head2 filename()

Returns the currently open filename or C<undef> if there is not currently a file
open on this batch object.

=cut

sub filename {
    my $self = shift;

    return $self->{filename};
}


1;

__END__

=head1 RELATED MODULES

L<MAB::File>, L<MAB::File::MAB2>, L<MAB::Record>.

=cut

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MAB::Batch

=head1 ACKNOWLEDGEMENTS

This program is inspired by and designed after L<MARC::Batch>.  

=head1 AUTHOR

Johann Rolschewski, C<< <rolschewski at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Johann Rolschewski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut