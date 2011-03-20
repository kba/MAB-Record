#!perl -Tw

use strict;
use integer;

use constant SKIPS => 10;

use Test::More tests=> SKIPS + 3;
use File::Spec;

BEGIN {
    use_ok( 'MAB::File::MAB2' );
}

my $filename = File::Spec->catfile( 't', 'journals.mab2' );
my $file = MAB::File::MAB2->in( $filename );
isa_ok( $file, 'MAB::File::MAB2', 'MAB2 file' );

my $mab;
for ( 1..SKIPS ) { # Skip to record with id 1480287-9
    $mab = $file->next( );
    isa_ok( $mab, 'MAB::Record', 'Got a record' );
}

is( $mab->record_id(), '1480287-9' );

$file->close;