#             CREATED BY STEVE CERRA - VERSION 1.1
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


# The comments included in the original code were mostly removed to save space
# due to having to copy/paste it constantly for testing on live services.
# I will be re-adding them soon.

#!/usr/bin/perl
use warnings;
use strict;
chomp(@ARGV); 
my $choice = "@ARGV";
my %hash = ();
my @result = ();
my @curr = ();
my @cache = ();
my $grepp;

my @vms = `grep "vifname" /home/xen/vm*/*.cfg`;

foreach (@vms) {
	# $1 = VM	$2 = DEVICE
	$_ =~ /.*?(vm\d+)\.cfg:.*?vifname=(.*)?,\s+mac/;
	$hash{$2} = $1;
	
	if (!($grepp)) {
		$2 =~ /(tap-vifvm|tap|vifvm)\d+\.\d+/;
		$grepp = $1;
	}
}

while (1) {
        getstats();
        print `clear`;
        print "VM\t\tINCOMING BW\tOUTGOING BW\tTOTAL BW\tPACKETS/S\n";
#        for my $r (0..$#result) { #Too many VMS to output all, doing top 10 for now.
        for my $r (0..9) {
			print $result[$r][0], "\t\t", $result[$r][1], "Kb/s\t\t", $result[$r][2], "Kb/s\t\t", $result[$r][3], "Kb/s\t\t", $result[$r][4], "/sec", "\n";
        }
        sleep 1;
        @result = ();
        @curr = ();
}

sub getstats {
        my $stats = `cat /proc/net/dev |grep $grepp`; 
        my $i = (scalar keys %hash) - 1;
        my $a = 0;
		foreach my $netif(keys %hash) {
			$stats =~ /$netif(:|:\s+)(\d+)\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+/;
			# $2 = BYTES-RECV       $3 = PKTS-RECV          $4 = BYTES-SENT         $5 = PKTS-SENT
			push @{$curr[$a]}, $hash{$netif};
			collect($a++, $2, $3, $4, $5);
        }
        calc();
}

sub collect {
        for my $z (1..4) {
                push @{$curr[$_[0]]}, $_[$z];
        }
        push @{$curr[$_[0]]}, ($curr[$_[0]][1]+$curr[$_[0]][3]);
        push @{$curr[$_[0]]}, ($curr[$_[0]][2]+$curr[$_[0]][4]);
}

sub calc {
        if (!($cache[0][0])) {
                cache();
        }
        for my $y (0..$#curr) {
                push @{$result[$y]}, $curr[$y][0];
                push @{$result[$y]}, int((($curr[$y][1]-$cache[$y][1])/1024)/8);
                push @{$result[$y]}, int((($curr[$y][3]-$cache[$y][3])/1024)/8);
                push @{$result[$y]}, int((($curr[$y][5]-$cache[$y][5])/1024)/8);
                push @{$result[$y]}, ($curr[$y][6]-$cache[$y][6]);
        }
        sorting();
        cache();
}

sub sorting {
        if ($choice eq "-p") {
                @result = sort { $b->[4] <=> $a->[4] } @result;
        } elsif ($choice eq "-i") {
                @result = sort { $b->[1] <=> $a->[1] } @result;
        } elsif ($choice eq "-o") {
                @result = sort { $b->[2] <=> $a->[2] } @result;
        } else {
                @result = sort { $b->[3] <=> $a->[3] } @result;
        }
}

sub cache {
        @cache = map { [@$_] } @curr;
}
