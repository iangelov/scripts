#!/usr/bin/perl
use strict;use warnings;

my $Protocols = {};
my $Ciphers   = {};

die "Usage: $0 log_file_name/s\n" if (scalar(@ARGV) < 1);

foreach my $File (@ARGV) {
    open(my $FH, '<', $File) or warn "$File: $!\n\n" and next;

    while (<$FH>) {
        chomp;
        $_ =~ s/^.*"(SSL[0-9a-zA-Z]{1,3}|TLSv[0-9]|TLSv[0-9]\.[0-9]):([^\"]*)".*$/$1:$2/g or next;
        my ($Protocol, $Cipher) = split(/:/, $_);
        $Protocols->{$Protocol}->{'count'}++;
        $Protocols->{$Protocol}->{$Cipher}->{'count'}++;
        $Ciphers->{$Cipher}->{'count'}++;
    }

    close($FH) or warn $!;
    keys(%{$Protocols}) or warn "$File: No SSL/TLS connections detected\n\n";
}

my $protoSum = 0;
foreach my $proto (sort keys %{$Protocols}) {
    $protoSum = $protoSum + $Protocols->{$proto}->{'count'};
}

print "Breakdown by SSL/TLS Protocol:\n";
foreach my $proto (sort { $Protocols->{$b}->{'count'} <=> $Protocols->{$a}->{'count'} } keys %{$Protocols}) {
    printf "$proto occurences: $Protocols->{$proto}->{'count'} %.2f%%\n",
        $Protocols->{$proto}->{'count'}/$protoSum*100;
}
print "\n";

my $ciphSum = 0;
foreach my $ciph (sort keys %{$Ciphers}) {
    $ciphSum = $ciphSum + $Ciphers->{$ciph}->{'count'};
}

print "Breakdown by SSL/TLS cipher:\n";
foreach my $ciph (sort { $Ciphers->{$b}->{'count'} <=> $Ciphers->{$a}->{'count'} } keys %{$Ciphers}) {
    printf "$ciph occurences: $Ciphers->{$ciph}->{'count'} %.2f%%\n",
        $Ciphers->{$ciph}->{'count'}/$ciphSum*100;
}
print "\n";

my $protociphSum = 0;
foreach my $currproto (sort keys %{$Protocols}) {
    foreach my $protociph (sort keys %{$Protocols->{$currproto}}) {
        $protociphSum = $protociphSum + $Protocols->{$currproto}->{$protociph}->{'count'}
            if $protociph !~ /count/;
    }
}

print "Breakdown by SSL/TLS protocol:cipher pair:\n";
foreach my $currproto (sort keys %{$Protocols}) {
    foreach my $protociph (sort { $Protocols->{$currproto}->{$b}->{'count'} <=> $Protocols->{$currproto}->{$a}->{'count'} } grep { !/count/ } keys %{$Protocols->{$currproto}}) {
        printf "$currproto:$protociph occurences: " .
            "$Protocols->{$currproto}->{$protociph}->{'count'} %.2f%%\n",
            $Protocols->{$currproto}->{$protociph}->{'count'}/$protociphSum*100;
            #if $protociph !~ /count/;
    }
}
print "\n";
