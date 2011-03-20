#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MAB::Record' ) || print "Bail out!
";
}

diag( "Testing MAB::Record $MAB::Record::VERSION, Perl $], $^X" );
