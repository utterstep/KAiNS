#!/usr/bin/perl

use File::Copy;
use English;
do 'bmp_steg.pl';

sub clear {
	if ($OSNAME =~ m/win/i) { system "cls" }
	else { system "clear"}
}

START:

clear;
print "1. Write to file\n2. Read from file\n\n0. Exit\n\nEnter what do you want to do: ";

chomp ($choice = <>);

goto START if ($choice !~ /[0-2]{1}/);

if ($choice == 1) {
	clear;
	print "Enter text (Ctrl-Z to stop):\n";
	@text = <>;
	$text = join ('', @text);
	copy("in.bmp","out.bmp") or die "Copy failed: $!";
	$time = time;
	write2Bmp ($text, "out.bmp");
	$time = time - $time;
	print "Done in $time seconds.\n"
}

elsif ($choice == 2) {
	print "Enter name of file: ";
	chomp ($file=<>);
	$time = time;
	$text = readBmp ($file);
	clear;
	$time = time - $time;
	print "There was:\n$text\n\nDone in $time seconds.";
}