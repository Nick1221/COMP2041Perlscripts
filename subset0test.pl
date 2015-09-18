#!/usr/bin/perl -w
#Used to test subset0


foreach my $file (glob "examples/0/*.sh"){
	print "Testing $file\n";
	system("sh $file > sh.output");
	my $shfile = $file;
	$file =~ s/\.sh/\.py/;
	$file =~ s/examples\/0\///;
	system("./shpy.pl $shfile > $file");
	system("python -u $file > py.output");
	system("diff py.output sh.output && echo success");
}
