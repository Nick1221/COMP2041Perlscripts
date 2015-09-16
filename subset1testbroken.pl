#!/usr/bin/perl -w
#Used to test subset0


foreach my $file (glob "examples/1/*.sh"){
	system("sh $file >sh.output");
	my $shfile = $file;
	$file =~ s/\.sh/\.py/;
	system("./shpy.pl $shfile > $file");
	system("python -u $file > py.output");
	system("diff py.output sh.output && echo success");
}
