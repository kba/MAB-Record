#!/usr/bin/perl

use v5.12;
use strict;
use warnings;
use warnings;
use warnings  qw(FATAL utf8);
use open      qw(:std :utf8);

use MAB::Record;
use MAB::File::MABdis;
use MAB::File::MABxml;

use Getopt::Long;
my ($help, $file_in, $file_out);

usage() if ( $#ARGV < 0 or
          ! GetOptions('help' => \$help, 'in=s' => \$file_in, 'out=s' => \$file_out)
          or !$file_in or !$file_out
          or defined $help );
 
sub usage
{
  say "Unknown option: @_" if ( @_ );
  say "usage: mabdis2mabxml.pl [--in file.dis] [--out file.xml] [--help]";
  say "\nfile.dis must be a CP850 encoded MAB-Diskette file.\nfile.xml will be a UTF-8 encoded MABxml file." if $help;
  exit;
}

$/ = "\n\n";

open(my $fh_in, '<:encoding(CP850)', $file_in) or die "Could not open $file_in: $!";
open(my $fh_out, '>:encoding(UTF-8)', $file_out) or die "Could not open $file_out: $!";

say $fh_out q|<?xml version="1.0" encoding="UTF-8" ?>|;
say $fh_out q|<datei>|;

while ( my $mab = <$fh_in> ) {
    chomp($mab);
    my $record = MAB::File::MABdis::decode($mab);
    my $xml = MAB::File::MABxml::encode($record);
    print $fh_out $xml;
}

say $fh_out q|</datei>|;

close $fh_in;
close $fh_out;
