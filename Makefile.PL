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
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MAB-Record-*' },
);
