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
			$line =~ s/print "/print /;
			$line =~ s{^\s+|\s+$}{}g;	#Removes trailing and leading whitespaces
			my @vars = split/ /,$line;
			shift (@vars);
			foreach my $ele (@vars){
		    	if ($ele =~ m/^[^\$]/){
					$ele = "'".$ele."'";
				} else {
					$ele =~ s/\$//;
				}
			 }
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
        my $varexist = 0;
		foreach $ele (@tempvar){ 
			if ( $ele =~ m/[^0-9]/ ){
                if ($ele =~ m/\.+/){
                    $ele = '"'.$ele.'"';
                    $varexist = 1;
                } else {
				    $ele = "'".$ele."'"
                }
			}
		}
        if ($varexist == 1){
            $import{"glob"} = 1;
            $line = $line . "sorted(glob.glob(".(join( ", ", @tempvar)).")):";
        } else {
		#Have to figure out how to add qutation marks to only words.
		#Edit: Think it's sorted for now. Not sure if it'll work with other cases atm
		    $line = $line.(join( ", ", @tempvar)).":";  
        }
		push (@translated, $line);
	} elsif ($line =~ /^[\t\s]*cd/){
		$import{"os"} = 1;
        $line =~ s/cd /os.chdir('/;
        $line = $line."')";
        push (@translated, $line);
	} elsif ($line =~ /^[\t\s]*$/){
		#Fixing Empty line
		$line = "\n";
        push (@translated, $line);
    } elsif ($line =~ /^[\t\s]*exit/){
        $import{"sys"} = 1;
        $line =~ s/exit /sys.exit(/;
        $line = $line . ")";
        push (@translated, $line);
	} elsif ($line =~ /^[\t\s]*read/){
		$import{"sys"} = 1;
		$line =~ s/read //;
		my $var = $line;
		#print "$var\n";
		$line = "$var = sys.stdin.readline().rstrip()";
		push (@translated, $line);
	} elsif ($line =~ /^[\t\s]*do$/){
		#There will be more added to accomodate other cases just for identation
		$identation+=4;
	} elsif ($line =~ /^[\t\s]*done$/){
		#There will be more added to accomodate other cases just for identation
		$identation-=4;
    } else {
        # Lines we can't translate are turned into comments
        $line =  "#$line\n";
        push (@translated, $line);
    }
}
#Subject to change
if (%import){ #If hash is empty dont do imports
    $importline = "import ".(join(", ", sort(keys %import)));
    print "$importline\n";
}
foreach my $ele (@translated){
    print "$ele\n";
}

