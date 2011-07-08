#!perl -Tw

use strict;
use integer;
use File::Spec;

use Test::More tests=>2;

BEGIN: {
    use_ok( 'MAB::Batch' );
}

# Test batch mode for MAB2 records
MAB2: {
    my $filename = File::Spec->catfile( 't', 'journals.mab2' );
    my $batch = new MAB::Batch( 'MAB2', $filename );
    $batch->warnings_off();
    isa_ok( $batch, 'MAB::Batch', 'MAB batch' );

    while ( my $mab = $batch->next() ) {
        isa_ok( $mab, 'MAB::Record' );

        my $f001 = $mab->field( '001' );
        isa_ok( $f001, 'MAB::Field' );
    }
}