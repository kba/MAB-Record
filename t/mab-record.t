#!perl -Tw

use Test::More ( tests => 7 );

use strict;


BEGIN {
    use_ok( 'MAB::Record' );
}

my $mab = q[x0560nM2.01200024      h001 2415107-5002a20080311003 20100309113205004 20110211025a987874829025o502377032025z2415107-5026 ZDB2415107-5030 b|zucz|z|||37037beng050 ||||||||g|||||052 p||||||z|||||||058 cr||||||||||||070 8999070aDNB070b9999331 Code4Lib journal334 Elektronische Ressource335 C4LJ370aC4LJ405 1.2007 -410 [S.l.]425b2007542aISSN 1940-5758652aaOnline-Ressource653 aOnline-Ressource655 uhttp://journal.code4lib.org/xVerlagzkostenfrei655 uhttp://www.bibliothek.uni-regensburg.de/ezeit/?2415107xEZB700 |020‡ZDB700z|135];

my $record = MAB::Record::new_from_mab2($mab);
isa_ok( $record, 'MAB::Record' );
isa_ok( $record->field('025', 'z'), 'MAB::Field' );
my $subfield = $record->subfield('655', ' ', 'u');
is( $subfield, 'http://journal.code4lib.org/', 'subfield() in scalar context' );
is($record->title(), 'Code4Lib journal', '$record->title()');
is($record->record_id(), '2415107-5', 'record_id()');
is($record->record_length(), 'x0560', 'record_length()');