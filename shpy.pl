#!/usr/bin/perl -w

# written by andrewt@cse.unsw.edu.au August 2015
# as a starting point for COMP2041/9041 assignment 
# http://cgi.cse.unsw.edu.au/~cs2041/assignment/shpy


$import = 0;
$identation = 0;
while ($line = <>) {
    chomp $line;
    if ($line =~ /^#!/ && $. == 1) {
        print "#!/usr/bin/python2.7 -u\n";
    } elsif ($line =~ /echo/) {
        #This should take echo and change it to print, and add quotation marks
        $line =~ s/echo /print "/;
        if ($line =~ /\$+/){
            $line =~ s/print \"//;
			#print "$line\n";
			my @vars = split/\$/,$line;
			shift (@vars);
			s{^\s+|\s+$}{}g foreach @vars;  #Removes trailing and leading whitespaces
			#foreach $ele (@vars){
			#	print "$ele end\n";
			#}
			$line = (" "x$identation)."print ".(join(", ", @vars));
        } else {
    		$line = $line . '"';
        }
		print "$line\n";
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
	} elsif ($line =~ /for .* in/){
		my @object = split/in/, $line;
		s{^\s+|\s+$}{}g foreach @object; #Removes trailing and leading whitespaces
		$line = shift(@object)." in ";
		my $tempvar = (shift(@object));
		print "$tempvar\n";
		#Have to figure out how to add qutation marks to only words.
		print "$line\n";
		#$forloopc += 1;
	} elsif ($line =~ /^$/){
		#Fixing Empty line
		print "\n";
	} elsif ($line =~ /^do$/){
		#There will be more added to accomodate other cases just for identation
		$identation+=4;
	} elsif ($line =~ /^done$/){
		#There will be more added to accomodate other cases just for identation
		$identation-=4;
    } else {
        # Lines we can't translate are turned into comments
        print "#$line\n";
    }
}
