#!/usr/bin/perl -w
#Used to test subset4


foreach my $file (glob "examples/4/*.sh"){
	print "Testing $file\n";
	if ($file eq "examples/4/sequence1.sh"){
		system("sh $file 1 10 > sh.output");
		my $shfile = $file;
		$file =~ s/\.sh/\.py/;
		$file =~ s/examples\/4\///;
		system("./shpy.pl $shfile > $file");
		system("python -u $file 1 10 > py.output");
		system("diff py.output sh.output && echo success");
	} else {
		system("sh $file > sh.output");
		my $shfile = $file;
		$file =~ s/\.sh/\.py/;
		$file =~ s/examples\/4\///;
		system("./shpy.pl $shfile > $file");
		system("python -u $file > py.output");
		system("diff py.output sh.output && echo success");
	}

}
