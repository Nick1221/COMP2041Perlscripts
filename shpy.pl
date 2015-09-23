#!/usr/bin/perl -w

# written by andrewt@cse.unsw.edu.au August 2015
# as a starting point for COMP2041/9041 assignment 
# http://cgi.cse.unsw.edu.au/~cs2041/assignment/shpy


my %import;
$identation = 0;
my @translated; 
while ($line = <>) {
    $line =~ s{^[\s\t]+|[\s\t]+$}{}g;
	$comment = "";
	if ($line =~ /[^\']\$\@|[^\']\$\#|[^\']\$[0-9]/){
		$line = dolla($line);
	}
	if ($line =~ /.+[^\\\$\"]#.*/){ #Avoid the weird cases
		my @comments = split/\#/,$line;
		$comment = $comments[1];
		$comment =~ s/^\s+|\s+$//g;
		$line =~ s/#.*//g;
		$comment = "   #".$comment;
	}
	if ($line =~ /^#!/ && $. == 1) {
        print  "#!/usr/bin/python2.7 -u\n";
    } elsif ($line =~ /echo/) {
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
			 $line = "print ".(join(", ", @vars)); 
		} elsif ($line =~ /echo '.*'/){
			$line =~ s/echo /print /;
		} elsif ($line =~ /echo ".*"/){
			$line =~ s/echo /print /;
		} else {
			$line =~ s/echo[\s$quote]/print $quote/;	
    		$line = $line . $quote;
        }
		push (@translated, (" "x$identation).$line.$comment);
	} elsif ($line =~ /^[\t\s]*ls|^[\t\s]*pwd|^[\t\s]*id|^[\t\s]*date/){
		#This should change ls to subprocess. 
        #Changes whatever afterwards to join word by word.
        $import{"subprocess"} = 1;		
		$line = dolla($line);
		
		if ($line =~ m/-las/){
			$import{"sys"} = 1;
			#print "$line\n";
			$line =~ s/^\s+|\s+$//g;
			my @words = split /-las/,$line;
			s{^\s+|\s+$}{}g foreach @words; 
			my @vars = split/ /,$words[1];
			s{^\s+|\s+$}{}g foreach @vars; #Removes trailing and leading whitespaces
			#print "@words";
			$line =  "subprocess.call(['ls', '-las']";
			foreach $ele (@vars){
				#print "$ele\n";
				 if ($ele =~ m/^[\"]\$/){
		            $ele =~ s/[\"]\$//;
					$ele =~ s/[\"]//;
				}
			}
			$line = $line." + ".join(" + ", @vars).")";		
		} else {
			my @words = split / /,$line;
			$line =  "subprocess.call(['";
			$line = $line.(join( "','", @words))."'])";
		}
		push (@translated, (" "x$identation).$line .$comment);
    } elsif ($line =~ /[a-zA-Z0-9]+=.*/){
        #Handle Variable
		$line = dolla($line);
        my @words = split /=/,$line;
		if ($words[1] =~ m/^\$[0-9]+/){
			#means its a variable
			$import{"sys"} = 1;
			$words[1] =~ s/\$/sys.argv[/;
			$words[1] = $words[1]."]";
			$line = join(" = ", @words);
        } elsif ($words[1] =~ m/^\$[a-zA-Z]+/){
            $words[1] =~ s/\$//;
            $line = join(" = ", @words);
		} elsif ($words[1] =~ m/^\`.*\`/){
            $words[1] =~ s/\`//g;
            if ($words[1] =~ /expr/){
                $words[1]=~s/.*expr //;        
                $words[1] = expr($words[1]);
            }
            $line = join(" = ", @words);
        } elsif ($words[1] =~ m/^[0-9]+/){
            $line = join(" = ", @words);		
		} elsif ($words[1] =~ m/^\$\(\(/){
			$words[1] =~ s/\$\(\(/expr /g;
			$words[1] =~ s/\)\)//g;
            if ($words[1] =~ /expr/){ 
                $words[1]=~s/.*expr //;        
                $words[1] = expr($words[1]);
            }
			$line = join(" = ", @words);
		} elsif ($words[1] =~ m/^\$\([^\)]*\)/){
			$words[1] =~ s/\$\(/expr /g;
			$words[1] =~ s/\)//g;
            if ($words[1] =~ /expr/){
                $words[1]=~s/.*expr //;        
                $words[1] = expr($words[1]);
            }
            $line = join(" = ", @words);
        } else {
	        $line = join(" = \'", @words)."'";
		}
		#print "$identation\n";
        push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /for .* in/){
		$line = dolla($line);
		$line = basicop($line);
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
		push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /if test|elif test|if \[/){
		#print "$line\n";
			
		#rint "Doing ifs\n";
		if ($line =~ /if *\[.*\]$/){
            $line =~ s/if \[ //;
            $line =~ s/\]//;
            $newline1 = "if ";
        } elsif ($line =~ /if test/){
			$line =~ s/if test //;
			$newline1 = "if ";
			#print "$line\n";
		} elsif ($line =~ /elif test/){
			$line =~ s/elif test //;
			$newline1 = "elif ";
		} 
		$line = dolla($line);
		if ($line =~ m/-r/){
			$import{"os"} = 1;
			$line =~ s/-r//;
			$line =~ s{^\s+|\s+$}{}g;
			if ($line =~ /\$.*/){
				$line =~ s/\$//;
			} else {
				$line = "'".$line."'";
			}
			#print "$line\n";
			
			$newline = $newline1."os.access($line, os.R_OK):"
		} elsif ($line =~ m/-d/){
			$import{"os.path"} = 1;
			$line =~ s/-d//;
			$line =~ s{^\s+|\s+$}{}g;
			$newline = $newline1."os.path.isdir('".$line."'):";	
		} elsif ($line =~ m/\-../){
			$line = basicop($line);
			$newline = $newline1.$line;
		} else {
			#print "$newline\n";
			my @vars = split/=/, $line;
			s{^\s+|\s+$}{}g foreach @vars;
			foreach $ele (@vars){ 
				if ($ele =~ m/^\$[^\#\@]/){
		            $ele =~ s/\$//;
				} else {
					$ele = "'".$ele."'";
				}
			}
			$newline = $newline1.(join(" == ",@vars)).":";
		}
		
		#print "$line\n";
		#
		#$line = "if ".$line;
		push (@translated, (" "x$identation).$newline .$comment);
    } elsif ($line =~ /^while/){
		if ($line =~ /^while test/){		
			$line =~ s/while test //;
		} elsif ($line =~ /^while \[/){
			$line =~ s/while \[ //;
			$line =~ s/\]//;
		} elsif ($line =~ /^while true/){
			$import{"subprocess"} = 1;
			$line =~ s/while true/not subprocess\.call\(\[\'true\'\]\)\:/;
		}        
		$line = dolla($line);
		$line = basicop($line);
		$line = "while ".$line;
        push (@translated, (" "x$identation).$line.$comment);
	} elsif ($line =~ /^[\t\s]*cd/){
		$import{"os"} = 1;
        $line =~ s/cd /os.chdir('/;
        $line = $line."')";
        push (@translated, (" "x$identation).$line .$comment);
    } elsif ($line =~ /^[\t\s]*exit/){
        $import{"sys"} = 1;
        $line =~ s/exit /sys.exit(/;
        $line = $line . ")";
        $line = $line."   #".$comment;
		push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /^[\t\s]*read/){
		$import{"sys"} = 1;
		$line =~ s/read //;
		my $var = $line;
		#print "$var\n";
		$line = "$var = sys.stdin.readline().rstrip()";
		push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /^rm/){
		my @var = split/ /, $line;
		foreach $ele (@var){
			if ($ele =~ /^\$/){
				$ele =~ s/\$/str\(/;
				$ele = $ele.")";
			} else {
				$ele = "'".$ele."'";
			}
		}
		$line = "subprocess.call([".(join(", ", @var))."])";
		push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /^[\t\s]*else$/){
		$line =~ s/else/else:/;
		push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /^#/){
		push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /^[\t\s]*$/){
		#Fixing Empty line
		$line = "";
        push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /^[\t\s]*do$|^[\t\s]*then$/){
		#There will be more added to accomodate other cases just for identation
		$identation+=4;
		
	} elsif ($line =~ /^[\t\s]*done$|^[\t\s]*fi$/){
		#There will be more added to accomodate other cases just for identation
		$identation-=4;
    } else {
        # Lines we can't translate are turned into comments
        $line =  "#$line";
        push (@translated, (" "x$identation).$line .$comment);
    }
}
#Subject to change
if (%import){ #If hash is empty dont do imports
	foreach $key (sort(keys %import)){
		$importline = "import $key";
	    print "$importline\n";
	}
}
foreach my $ele (@translated){
    print "$ele\n";
}


#Functions

sub expr {
    #Convert expr
    my $expr = $_[0];
    my @vars = split/ /, $expr;
    foreach $ele (@vars){
        if ($ele =~ /^\$.*/){
            $ele =~ s/\$/int(/;
            $ele = $ele.")";
        } elsif ($ele =~ /^'[^']*'/){
			$ele =~ s/^'//;
			$ele =~ s/'$//;
		}
    }
    $expr = join(" ", @vars);
    return $expr;
}

sub dolla {
	my $linech = $_[0];
	#my $temparg = "";
	if ($linech =~ m/[^\']*\$\@[^\']/){
		$linech =~ s/[^\']\$\@[^\']/ sys\.argv\[1\:\] /;
	} elsif ($linech =~ m/[^\']*\$#/){
		$linech =~ s/[^\']\$\#[^\']/ len\(sys\.argv\[1\:\]\) /;
		#$temparg = "len(sys.argv[1:])";
		#print "$linech\n";
	} elsif ($linech =~ m/[^\']*\$[0-9][^\']/){
		$digit = $linech;
		$digit =~ s/\D//g;
		$linech =~ s/[^\']\$[0-9][^\']/ sys\.argv\[$digit\] /;
		#$temparg = "sys.argv[$digit]";
	} 
	return $linech;
}


sub basicop {
	my $line = $_[0];
	$newline = "";
		if ($line =~ /\-le/){
            my @vars = split/-le/, $line;
            s{^\s+|\s+$}{}g foreach @vars;
            foreach $ele (@vars){
				if ($ele =~ m/^\$[^\#\@]/){
		            $ele =~ s/\$//;
		            $ele = "int(".$ele.")";
				}
            }
            $newline = $newline.(join(" <= ", @vars)).":";
        } elsif ($line =~ /\-ge/){
			my @vars = split/-ge/, $line;
            s{^\s+|\s+$}{}g foreach @vars;
            foreach $ele (@vars){
                if ($ele =~ m/^\$/){
		            $ele =~ s/\$//;
		            $ele = "int(".$ele.")";
				}
            }
            $newline = $newline.(join(" >= ", @vars)).":";
		} elsif ($line =~ /\-gt/){
			my @vars = split/-gt/, $line;
            s{^\s+|\s+$}{}g foreach @vars;
            foreach $ele (@vars){
                if ($ele =~ m/^\$/){
		            $ele =~ s/\$//;
		            $ele = "int(".$ele.")";
				}
            }
            $newline = $newline.(join(" > ", @vars)).":";
		} elsif ($line =~ /\-lt/){
			my @vars = split/-lt/, $line;
            s{^\s+|\s+$}{}g foreach @vars;
            foreach $ele (@vars){
                if ($ele =~ m/^\$/){
		            $ele =~ s/\$//;
		            $ele = "int(".$ele.")";
				}
            }
            $newline = $newline.(join(" < ", @vars)).":";
		} elsif ($line =~ /\-eq/){
			my @vars = split/-eq/, $line;
            s{^\s+|\s+$}{}g foreach @vars;
            foreach $ele (@vars){
                if ($ele =~ m/^\$/){
		            $ele =~ s/\$//;
		            $ele = "int(".$ele.")";
				}
            }
            $newline = $newline.(join(" == ", @vars)).":";
		} elsif ($line =~ /\-ne/){
			my @vars = split/-ge/, $line;
            s{^\s+|\s+$}{}g foreach @vars;
            foreach $ele (@vars){
                if ($ele =~ m/^\$/){
		            $ele =~ s/\$//;
		            $ele = "int(".$ele.")";
				}
            }
            $newline = $newline.(join(" != ", @vars)).":";
		} else {
			$newline = $line;
			#print "$newline\n";
		}
	return $newline
}
