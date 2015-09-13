#!/usr/bin/perl -w

# written by andrewt@cse.unsw.edu.au August 2015
# as a starting point for COMP2041/9041 assignment 
# http://cgi.cse.unsw.edu.au/~cs2041/assignment/shpy

while ($line = <>) {
    chomp $line;
    if ($line =~ /^#!/ && $. == 1) {
        print "#!/usr/bin/python2.7\n";
    } elsif ($line =~ /echo/) {
		#This should take echo and change it to print, and add quotation marks
        $line =~ s/echo /print "/;
		$line = $line . '"';
		print "$line\n";
	} elsif ($line =~ /ls/){
		#This should change ls to glob	
		print "import glob\n";
		$line =~ s/ls /glob.glob\(\'/;
		$line = $line."')";
		print "$line\n";
    } else {
        # Lines we can't translate are turned into comments
        print "#$line\n";
    }
}
