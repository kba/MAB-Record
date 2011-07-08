#!perl -Tw

use Test::More tests => 9; 

use strict;

## make sure that MAB::Field::subfield() is aware of the context 
## in which it is called. In list context it returns *all* subfields
## and in scalar just the first.

use_ok( 'MAB::Field' );

my $field = MAB::Field->new( '655', ' ', 'u' => 'http://journal.code4lib.org/', 'z' => 'kostenfrei' );

isa_ok( $field, 'MAB::Field' );
is($field->tag(), '655', '$field->tag()');
is($field->indicator(), ' ', '$field->indicator()');

my @subfields = $field->subfields();
is_deeply(\@subfields, [ {'u' => 'http://journal.code4lib.org/'}, {'z' => 'kostenfrei'} ], 'subfields() returns same subfields');

$field = MAB::Field->new( '025', 'z', '126275-0' );
isa_ok( $field, 'MAB::Field' );
is($field->tag(), '025', '$field->tag()');
is($field->indicator(), 'z', '$field->indicator()');
my $data = $field->data();
is($field->data(), '126275-0', '$field->data()');