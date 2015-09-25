#!/usr/bin/perl -w

# written by andrewt@cse.unsw.edu.au August 2015
# as a starting point for COMP2041/9041 assignment 
# http://cgi.cse.unsw.edu.au/~cs2041/assignment/shpy


my %import;
$identation = 0;
my @translated; 
while ($line = <>) {
    $line =~ s{^[\s\t]+|[\s\t]+$}{}g;
	my $comment = "";
	#Change $@/#/number to its corresponding python syntax
	if ($line =~ /[^\']\$\@|[^\']\$\#|[^\']\$\d/){
		$line = dolla($line);
	}

	#If there's a comment at the EOL, take it out and readd it afterwards
	if ($line =~ m/[^"[^"]*"[^"]#/){ #Avoid the weird cases
		my @comments = split/\#/,$line;
		$comment = $comments[1];
		$comment =~ s/^\s+|\s+$//g;
		$line =~ s/#.*//g;
		$comment = "   #".$comment;
	}

	if ($line =~ /^#!/ && $. == 1) {
        print  "#!/usr/bin/python2.7 -u\n";
    } elsif ($line =~ /^echo/) {
		$line = echo($line);
		push (@translated, (" "x$identation).$line.$comment);
	} elsif ($line =~ /^[\t\s]*ls|^[\t\s]*pwd|^[\t\s]*id|^[\t\s]*date/){
		#This should change ls to subprocess. 
        #Changes whatever afterwards to join word by word.
        $import{"subprocess"} = 1;		
		
		if ($line =~ m/-las/){
			$import{"sys"} = 1;
			$line =~ s/^\s+|\s+$//g;
			my @words = split /-las/,$line;
			s{^\s+|\s+$}{}g foreach @words; 
			my @vars = split/ /,$words[1];
			s{^\s+|\s+$}{}g foreach @vars; #Removes trailing and leading whitespaces
			$line =  "subprocess.call(['ls', '-las']";
			foreach $ele (@vars){
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
        my @words = split /=/,$line;

		if ($words[1] =~ /^\`.*\`/){
            $words[1] =~ s/\`//g;
            if ($words[1] =~ m/expr/){
				#print "$words[1]\n";
                $words[1]=~s/.*expr //;        
                $words[1] = expr($words[1]);
            }    
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
        } elsif ($words[1] =~ m/^\$[a-zA-Z]+/){
            $words[1] =~ s/\$//g;
			$line = join(" = ", @words);
		} elsif ($words[1] =~ m/\.\//){
			$words[1] = "'".$words[1]."'";
			$line = join(" = ", @words);
		} elsif ($words[1] =~ m/sys\.arg/){
            $line = join(" = ", @words);
        } elsif ($words[1] =~ m/"[^"]*"/){
            $line = join(" = ", @words);
        } elsif ($words[1] =~ m/'[^']*'/){
            $line = join(" = ", @words);
        } else {
			#print "$line\n";
	        $line = join(" = \'", @words)."'";
		}
        
        push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /for .* in/){
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
		    $line = $line.(join( ", ", @tempvar)).":";  
        }
		push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /if test|elif test|if \[|if /){
		if ($line =~ /if *\[.*\]$/){
            $line =~ s/if \[ //;
            $line =~ s/\]$//;
            $newline1 = "if ";
        } elsif ($line =~ /^if test/){
			$line =~ s/if test //;
			$newline1 = "if ";
		} elsif ($line =~ /^elif test/){
			$line =~ s/elif test //;
			$newline1 = "elif ";
			$identation -= 4;
		} elsif ($line =~ /^if/){
			$line =~ s/if //;
			$newline1 = "if ";
		}
		if ($line =~ m/-r/){
			$import{"os"} = 1;
			$line =~ s/-r//;
			$line =~ s{^\s+|\s+$}{}g;
			if ($line =~ /\$.*/){
				$line =~ s/\$//;
			} else {
				$line = "'".$line."'";
			}
			
			$newline = $newline1."os.access($line, os.R_OK):"
		} elsif ($line =~ m/-d/){
			$import{"os.path"} = 1;
			$line =~ s/-d//;
			$line =~ s{^\s+|\s+$}{}g;
			$newline = $newline1."os.path.isdir('".$line."'):";	
		} elsif ($line =~ m/fgrep/){
			my @vars = split/ /,$line;
			foreach my $ele (@vars){
		    	if ($ele =~ m/^[^\$]/){
					$ele = "'".$ele."'";
				} elsif ($ele =~ m/^\$[0-9]+/) {
					$import{"sys"} = 1;
					$ele =~ s/\$/sys.argv[/;
					$ele = $ele."]";
				} else {
					$ele =~ s/\$/str\(/;
					$ele = $ele.")";
				}
			 }
			$newline = $newline1."not subprocess.call([".join(" , ", @vars)."]):";
		} elsif ($line =~ m/\-../){
			$line = basicop($line);
			$newline = $newline1.$line.":";
		} else {
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
		push (@translated, (" "x$identation).$newline.$comment);
	} elsif ($line =~ /^case/){
		$line = basicop($line);
		$line =~ s/case //;
		$line =~ s/ in//;	
		if ($line =~ m/".*"/){
			$line =~ s/"//g;
		}
		if ($line =~ m/\$.*/){
			$line =~ s/\$//;
		}
		$case = $line;
	} elsif ($line =~ /[^\)]+\)/){
		my @var = split/\)/,$line;
		my $var = $var[0];
		
		#print "$var\n";
		$line = "if $case == $var:";
		push (@translated, (" "x$identation).$line.$comment);
		$line2 = echo($var[1]);
		$identation +=4;
		push (@translated, (" "x$identation).$line2.$comment);
		$identation -=4;
	} elsif ($line =~ /^;;/){
		$line =~ "";
    } elsif ($line =~ /^while/){
		if ($line =~ /^while test/){		
			$line =~ s/while test //;
		} elsif ($line =~ /^while \[/){
			$line =~ s/while \[ //;
			$line =~ s/\]//;
		} elsif ($line =~ /^while true/){
			$import{"subprocess"} = 1;
			$line =~ s/while true/not subprocess\.call\(\[\'true\'\]\)/;
		}        
		$line = basicop($line);
		$line = "while ".$line.":";
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
		push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /^[\t\s]*read/){
		$import{"sys"} = 1;
		$line =~ s/read //;
		my $var = $line;
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
		$identation-=4;
		$line =~ s/else/else:/;
		push (@translated, (" "x$identation).$line .$comment);
		$identation+=4;
	} elsif ($line =~ /^#/){
		push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /^[\t\s]*$/){
		#Fixing Empty line
		$line = "";
        push (@translated, (" "x$identation).$line .$comment);
	} elsif ($line =~ /do$|then$/){
		#There will be more added to accomodate other cases just for identation
		$identation+=4;
	} elsif ($line =~ /^[\t\s]*done$|^[\t\s]*fi$|esac$/){
		#There will be more added to accomodate other cases just for identation
		$identation-=4;
    } else {
        # Lines we can't translate are turned into comments
        $line =  "#$line";
        push (@translated, (" "x$identation).$line .$comment);
    }
}
#Goes through hash and prints out the imports
if (%import){ #If hash is empty dont do imports
	foreach $key (sort(keys %import)){
		$importline = "import $key";
	    print "$importline\n";
	}
}
#Print the array out
foreach my $ele (@translated){
    print "$ele\n";
}


#Functions
sub expr {
    #Convert expr
    my $expr = $_[0];
    my @vars = split/ /, $expr;
    foreach $ele (@vars){
		#print "$ele\n";
        if ($ele =~ /^\$.*/){
            $ele =~ s/\$/int(/;
            $ele = $ele.")";
        } elsif ($ele =~ /^'[\*\/\+\-\%]'/){
			$ele =~ s/^'//;
			$ele =~ s/'$//;
		}
    }
    $expr = join(" ", @vars);
    return $expr;
}

#Convert $.
sub dolla {
	my $linech = $_[0];
	#my $temparg = "";
	if ($linech =~ m/[^\']*\$\@[^\']/){
		$linech =~ s/[^\']\$\@[^\']/ sys\.argv\[1\:\] /;
	} elsif ($linech =~ m/[^\']*\$\#/){
		$linech =~ s/[^\']\$\#[^\']/ len\(sys\.argv[1\:\]\) /;
		#$temparg = "len(sys.argv[1:])";
		#print "$linech\n";
	} elsif ($linech =~ m/[']?\$[0-9]+[']?/){
		$import{"sys"} = 1;
		my $digit = $linech;
		my @digits = split/ /, $digit;
		foreach $ele (@digits){
           # print "$ele\n";
		    if ($ele =~ /^\$/){
                $ele =~ s/^\$//;
                $digit = $ele;
            } elsif ($ele =~ /[^\$]*\$/){
                $ele =~ s/[^\$]*//;
                $ele =~ s/\$//;
                $digit = $ele;
            }
		}
		$linech =~ s/[']?\$[0-9]+[']?/sys\.argv\[$digit\]/;
		#print "$linech\n";
	} 
	
	#print "$linech\n";
	return $linech;
}

#Convert operations.
sub basicop {
	my $line = $_[0];
	$newline = "";
	my @vars = split/ /, $line;
    s{^\s+|\s+$}{}g foreach @vars;
	#$number -gt 100000000 -o  $number -lt -100000000 
	foreach my $ele (@vars){
		if ($ele =~ m/^\$[^\#\@]/){
		    $ele =~ s/\$//;
		    $ele = "int(".$ele.")";
		} elsif ($ele =~ m/\-o|\|\|/){
			$ele = "or";
		} elsif ($ele =~ m/\-a|&&/){
			$ele = "and";
		} elsif ($ele =~ m/\-lt/){
			$ele = "<";
		} elsif ($ele =~ m/\-le/){
			$ele = "<=";
		} elsif ($ele =~ m/\-ge/){
			$ele = ">=";
		} elsif ($ele =~ m/\-gt/){
			$ele = ">";
		} elsif ($ele =~ m/\-eq/){
			$ele = "==";
		} elsif ($ele =~ m/\-ne/){
			$ele = "!=";
		} 
	}
	$newline = join(" ", @vars);
	#print "$newline\n";
	return $newline
}


#Echo
sub echo {
	my $line = $_[0];
	if ($line =~ /echo "/){
		$quote = '"';
	} else {
		$quote = "'";
	}
	if ($line =~ m/\>\>\$file/){
		$line =~ s/\>\>\$file//;
		$line =~ s/echo //;
		if ($line =~ /\$/){
			$line =~ s/\$//;
		}
		$line = "with open(file, 'a') as f: print >>f, ".$line;
	} elsif ($line =~ /\$|sys/){            
		$line =~ s/echo[\s$quote]/print /;
		$line =~ s{^\s+|\s+$}{}g;	#Removes trailing and leading whitespaces
		my @vars = split/ /,$line;
		shift (@vars);
		foreach my $ele (@vars){
			$ele =~ s/"//g;
			if ($ele =~ m/sys\.arg/){
				$ele = '$'.$ele;
				#$ele =~ s/\]//;
			} 
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
	} elsif ($line =~ /echo$/){
		$line ="";
	} else {
		$line =~ s/echo[\s$quote]/print $quote/;	
    	$line = $line . $quote;
	}
	return $line;
}
