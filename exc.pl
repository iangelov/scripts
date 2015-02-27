#!/usr/bin/perl
use strict;use warnings;

die "Usage: $0 log_file_name/s\n" if (scalar(@ARGV) < 1);

# '17:32:11,634 ERROR ['
# 2012-11-08 00:00:50,693 ERROR [
# [2013-05-10 03:59:57,111][ERROR]
my $errRegexp = '(\[?\d{4}-\d{2}-\d{2} )?\d{2}:\d{2}:\d{2},\d{3}(\]| )\[?(ERROR|WARN)\]?';

foreach my $serverLog (@ARGV) {
    warn "Error with $serverLog\n" and next if (! -f $serverLog);
    my $mark = 0;
    open(FILE, '<', $serverLog);
    while (<FILE>) {
        # multiline errors
        $mark = 0 if (($_ =~ /^$|^\[/) or ($_ !~ /(^\s+|^[^0-9]+|^\[)/));
        next if (($_ !~ /^$errRegexp/) && !$mark);
        chomp;
        $mark = 1 && print "$_\n";
    }
}
