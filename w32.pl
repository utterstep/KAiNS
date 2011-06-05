#!/usr/bin/perl -w

use warnings;
use strict;
use Win32::GUI();
use lib qw(./lib);

require 'wav_steg.pm';
require 'bmp_steg.pm';

our $ver = '0.0.1';

my $main = Win32::GUI::Window->new(
	-name   => 'Main',
	-width  => 800,
	-height => 600,
	-text   => "KAinS by Utter, ver$ver",
);

$main->Show();
Win32::GUI::Dialog();