#!/usr/bin/perl -w
#Used to test subset3


foreach my $file (glob "examples/3/*.sh"){
	print "Testing $file\n";
	if ($file eq "examples/3/l.sh"){
		system("sh $file examples/0/*.sh > sh.output");
		my $shfile = $file;
		$file =~ s/\.sh/\.py/;
		$file =~ s/examples\/3\///;
		system("./shpy.pl $shfile > $file");
		system("python -u $file examples/0/*.sh > py.output");
		system("diff py.output sh.output && echo success");
	} elsif ($file eq "examples/3/sequence0.sh"){
		system("sh $file 1 10 > sh.output");
		my $shfile = $file;
		$file =~ s/\.sh/\.py/;
		$file =~ s/examples\/3\///;
		system("./shpy.pl $shfile > $file");
		system("python -u $file 1 10 > py.output");
		system("diff py.output sh.output && echo success");
	} else {
		system("sh $file > sh.output");
		my $shfile = $file;
		$file =~ s/\.sh/\.py/;
		$file =~ s/examples\/3\///;
		system("./shpy.pl $shfile > $file");
		system("python -u $file > py.output");
		system("diff py.output sh.output && echo success");
	}

}
