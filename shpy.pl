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
		if ($line =~ /echo "/){
			$quote = '"';
		} else {
			$quote = "'";
		}
       
        if ($line =~ /\$+/){            
			$line =~ s/echo[\s$quote]/print /;
			$line =~ s{^\s+|\s+$}{}g;	#Removes trailing and leading whitespaces
			my @vars = split/ /,$line;
			shift (@vars);
			foreach my $ele (@vars){
		    	if ($ele =~ m/^[^\$]/){
					$ele = "'".$ele."'";
				} elsif ($ele =~ m/^\$[0-9]+/) {
					$import{"sys"} = 1;
					$ele =~ s/\$/sys.argv[/;
					$ele = $ele."]";
				} else {
					$ele =~ s/\$//;
				}
			 }
			 $line = (" "x$identation)."print ".(join(", ", @vars)); 
		} elsif ($line =~ /echo '.*'/){
			$line =~ s/echo /print /;
		} elsif ($line =~ /echo ".*"/){
			$line =~ s/echo /print /;
		} else {
			$line =~ s/echo[\s$quote]/print $quote/;	
    		$line = $line . $quote;
        }
		push (@translated, $line);
	} elsif ($line =~ /^[\t\s]*ls|^[\t\s]*pwd|^[\t\s]*id|^[\t\s]*date/){
		#This should change ls to subprocess. 
        #Changes whatever afterwards to join word by word.
        $import{"subprocess"} = 1;
		if ($line =~ m/-las/){
			$import{"sys"} = 1;
			if ($line =~ m/"\$@"/){
				$temparg = "sys.argv[1:]";
				$line =~ s/"\$@"//;
			}
			#print "$line\n";
			$line =~ s/^\s+|\s+$//g;
			my @words = split / /,$line;
			$line =  "subprocess.call(['";
			$line = $line.(join( "','", @words))."'] + ".$temparg.")";		
		} else {
			my @words = split / /,$line;
			$line =  "subprocess.call(['";
			$line = $line.(join( "','", @words))."'])";
		}
		push (@translated, $line);
    } elsif ($line =~ /[a-zA-Z0-9]+=.*/){
        #Handle Variable
        my @words = split /=/,$line;
		if ($words[1] =~ m/^\$.*/){
			#means its a variable
			$import{"sys"} = 1;
			$words[1] =~ s/\$/sys.argv[/;
			$words[1] = $words[1]."]";
			$line = join(" = ", @words);
		} else {
	        $line = join(" = \'", @words)."'";
		}
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
	} elsif ($line =~ /^if test|^elif test/){
		#rint "Doing ifs\n";
		if ($line =~ /^if/){
			$line =~ s/if test //;
			$newline = "if ";
		} elsif ($line =~ /^elif/){
			$line =~ s/elif test //;
			$newline = "elif ";
		}
		if ($line =~ m/-r/){
			$import{"os"} = 1;
			$line =~ s/-r//;
			$line =~ s{^\s+|\s+$}{}g;
			$newline = $newline."os.access('".$line."', os.R_OK):"
		} elsif ($line =~ m/-d/){
			$import{"os.path"} = 1;
			$line =~ s/-d//;
			$line =~ s{^\s+|\s+$}{}g;
			$newline = $newline."os.path.isdir('".$line."'):"
		} else {
			my @vars = split/=/, $line;
			s{^\s+|\s+$}{}g foreach @vars;
			foreach $ele (@vars){ 
				$ele = "'".$ele."'";
			}
			$newline = $newline.(join(" == ",@vars)).":";
		}
		push (@translated, $newline);
	} elsif ($line =~ /^[\t\s]*else$/){
		$line =~ s/else/else:/;
		push (@translated, $line);
	} elsif ($line =~ /^#/){
		push (@translated, $line);
	} elsif ($line =~ /^[\t\s]*$/){
		#Fixing Empty line
		$line = "";
        push (@translated, $line);} elsif ($line =~ /^[\t\s]*do$|^[\t\s]*then$/){
		#There will be more added to accomodate other cases just for identation
		$identation+=4;
	} elsif ($line =~ /^[\t\s]*done$|^[\t\s]*fi$/){
		#There will be more added to accomodate other cases just for identation
		$identation-=4;
    } else {
        # Lines we can't translate are turned into comments
        $line =  "#$line";
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

