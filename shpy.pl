#!/usr/bin/perl -w

# written by andrewt@cse.unsw.edu.au August 2015
# as a starting point for COMP2041/9041 assignment 
# http://cgi.cse.unsw.edu.au/~cs2041/assignment/shpy


$import = 0;
while ($line = <>) {
    chomp $line;
    if ($line =~ /^#!/ && $. == 1) {
        print "#!/usr/bin/python2.7 -u\n";
    } elsif ($line =~ /echo/) {
        #This should take echo and change it to print, and add quotation marks
        $line =~ s/echo /print "/;
        if ($line =~ /\$+/){
            $line =~ s/[\$\"]//g;
            my @words = split / /,$line;
            shift @words; 
            $line = "print ".(join(", ", @words));
            print "$line\n";
        } else {
    		$line = $line . '"';
	    	print "$line\n";
        }
	} elsif ($line =~ /ls|pwd|id|date/){
		#This should change ls to subprocess. 
        #Changes whatever afterwards to join word by word.
		if ( $import == 0){
            print "import subprocess\n";
            $import = 1;
        }
		my @words = split / /,$line;
		$line =  "subprocess.call(['";
		$line = $line.(join( "','", @words))."'])";
		print "$line\n";
    } elsif ($line =~ /.*=.*/){
        #Handle Variable
        my @words = split /=/,$line;
        $line = join(" = \'", @words)."'";
        print "$line\n";
    } else {
        # Lines we can't translate are turned into comments
        print "#$line\n";
    }
}
