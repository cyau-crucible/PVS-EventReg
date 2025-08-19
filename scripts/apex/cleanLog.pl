#!/usr/bin/perl
use strict;
use warnings;

my $filename = $ARGV[0] or die "Usage: $0 <logfile>\n";

open(my $fh, '<', $filename) or die "Cannot open $filename: $!\n";

while (my $line = <$fh>) {
   print $line if $line =~ /USER_DEBUG/;
}

close($fh);