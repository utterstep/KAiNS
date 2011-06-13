#!/usr/bin/perl

use utf8;
use File::Copy;
use English;
require '../lib/png_steg.pm';
require '../lib/bmp_steg.pm';
require '../lib/bintools.pm';

sub clear {
	if ($OSNAME =~ m/win/i) { system "cls" }
	else { system "clear"}
}

START:

clear;
print "1. Write to file\n2. Read from file\n3. Define if file contains anything\n\n0. Exit\n\nEnter what do you want to do: ";

chomp ($choice = <>);

goto START if ($choice !~ /[0-3]{1}/);

if ($choice == 1) {
	clear;
	print "Enter text (Ctrl-Z to stop):\n";
	$text = <>;
	copy("3.png","out.png") or die "Copy failed: $!";
	$time = time;
	write2Png ($text, "out.png");
	$time = time - $time;
	print "Done in $time seconds.\n"
}

elsif ($choice == 2) {
	print "Enter name of file: ";
	chomp ($file=<>);
	$time = time;
	$text = readPng ($file);
	clear;
	$time = time - $time;
	print "There was:\n$text\n\nDone in $time seconds.\n;"
}

elsif ($choice == 3) {
	print "Enter name of file: ";
	chomp ($file=<>);
	$time = time;
	@text = isContainerPng ($file);
	clear;
	$time = time - $time;
	print "@text\n;"
}