#!/usr/bin/perl -w
#Used to test subset2


foreach my $file (glob "examples/2/*.sh"){
	print "Testing $file\n";
	if ($file eq "examples/2/args.sh"){
		system("sh $file 1 2 3 4 5 6 > sh.output");
		my $shfile = $file;
		$file =~ s/\.sh/\.py/;
		$file =~ s/examples\/2\///;
		system("./shpy.pl $shfile > $file");
		system("python -u $file 1 2 3 4 5 6 > py.output");
		system("diff py.output sh.output && echo success");
	} else {
		system("sh $file > sh.output");
		my $shfile = $file;
		$file =~ s/\.sh/\.py/;
		$file =~ s/examples\/2\///;
		system("./shpy.pl $shfile > $file");
		system("python -u $file > py.output");
		system("diff py.output sh.output && echo success");
	}
}
