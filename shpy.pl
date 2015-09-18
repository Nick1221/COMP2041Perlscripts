#!/usr/bin/perl -w

# written by andrewt@cse.unsw.edu.au August 2015
# as a starting point for COMP2041/9041 assignment 
# http://cgi.cse.unsw.edu.au/~cs2041/assignment/shpy


my %import;
$identation = 0;
my @translated; 
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
		push (@translated, $line);
	} elsif ($line =~ /ls|pwd|id|date/){
		#This should change ls to subprocess. 
        #Changes whatever afterwards to join word by word.
        $import{"subprocess"} = 1;
		my @words = split / /,$line;
		$line =  "subprocess.call(['";
		$line = $line.(join( "','", @words))."'])";
		push (@translated, $line);
    } elsif ($line =~ /.*=.*/){
        #Handle Variable
        my @words = split /=/,$line;
        $line = join(" = \'", @words)."'";
        push (@translated, $line);
	} elsif ($line =~ /for .* in/){
		my @object = split/in/, $line;
		s{^\s+|\s+$}{}g foreach @object; #Removes trailing and leading whitespaces
		$line = shift(@object)." in ";
		my @tempvar = (split / /,shift(@object));
		foreach $ele (@tempvar){ 
			if ( $ele =~ m/[^0-9]/ ){
				$ele = "'".$ele."'"
			}
		}
		#Have to figure out how to add qutation marks to only words.
		#Edit: Think it's sorted for now. Not sure if it'll work with other cases atm
		$line = $line.(join( ", ", @tempvar)).":";
		push (@translated, $line);
	} elsif ($line =~ /^cd/){
		$import{"os"} = 1;
        $line =~ s/cd /os.chdir('/;
        $line = $line."')";
        push (@translated, $line);
	} elsif ($line =~ /^$/){
		#Fixing Empty line
		$line = "\n";
        push (@translated, $line);
	} elsif ($line =~ /^do$/){
		#There will be more added to accomodate other cases just for identation
		$identation+=4;
	} elsif ($line =~ /^done$/){
		#There will be more added to accomodate other cases just for identation
		$identation-=4;
    } else {
        # Lines we can't translate are turned into comments
        $line =  "#$line\n";
        push (@translated, $line);
    }
}
#Subject to change
$importline = "import ".(join(", ", sort(keys %import)));
print "$importline\n";
foreach my $ele (@translated){
    print "$ele\n";
}

