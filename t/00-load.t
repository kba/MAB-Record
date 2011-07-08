#!perl -T

use Test::More tests => 7;

BEGIN {
    use_ok( 'MAB::Record' ) || print "Could not load MAB::Record";
    use_ok( 'MAB::Field' ) || print "Could not load MAB::Field";
    use_ok( 'MAB::File' ) || print "Could not load MAB::File";
    use_ok( 'MAB::Batch' ) || print "Could not load MAB::Batch";
    use_ok( 'MAB::File::MAB2' ) || print "Could not load MAB::File::MAB2";
    use_ok( 'MAB::File::MABjson' ) || print "Could not load MAB::File::MABjson";
    use_ok( 'MAB::File::MABxml' ) || print "Could not load MAB::File::MABxml";
}

diag( "Testing distribution MAB::Record $MAB::Record::VERSION, Perl $], $^X" );
