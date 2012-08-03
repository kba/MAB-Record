use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MAB::Record',
    AUTHOR              => q{Johann Rolschewski <rolschewski@gmail.com>},
    VERSION_FROM        => 'lib/MAB/Record.pm',
    ABSTRACT_FROM       => 'lib/MAB/Record.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Mojo::JSON' => 0,
        'Test::More' => 0,
        'XML::Parser' => 0,
        'XML::Writer' => 0,
    },
    MIN_PERL_VERSION  => '5.12.0',
    'EXE_FILES'     =>  [ 'bin/mabdis2mabxml.pl' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MAB-Record-*' },
);
