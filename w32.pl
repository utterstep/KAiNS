#!/usr/bin/perl -w

use warnings;
use strict;
use Win32::GUI();
use lib qw(./lib);

require 'bintools.pm'; #loading module for binary op's

require 'wav_steg.pm'; #...module for wav...
require 'bmp_steg.pm'; #and bmp steganorgaphy

our $ver = '0.0.1';

my $main = Win32::GUI::Window->new(
	-name	=> 'Main',
	-minwidth	=> 805,
	-minheight	=> 620,
	-text	=> "KAinS by Utter, ver$ver",
);

my $font = Win32::GUI::Font->new(
	-size => 10,
);

my $menu = $main->AddMenu();

my $text_e = $main->AddTextfield(
	-name	=> "Steg",
	-font	=> $font,
	-left	=> 10,
	-top	=> 40,
	-width	=> 380,
	-height	=> 490,
	-multiline => 1,
	-vscroll=> 1,
);

my $text_d = $main->AddTextfield(
	-name	=> "UnSteg",
	-font	=> $font,
	-left	=> 400,
	-top	=> 40,
	-width	=> 380,
	-height	=> 490,
	-multiline => 1,
	-vscroll=> 1,
);

# my $scroll1 = Win32::GUI::UpDown->new();
# my $scroll2 = Win32::GUI::UpDown->new();

# $scroll1->Buddy($text_enc);
# $scroll2->Buddy($text_dec);

$main->AddButton(
	-name	=> "StegButton",
	-text	=> "Записать в файл",
	# -default=> 1,
	# -ok		=> 1,
	-width	=> 100,
	-height	=> 30,
	-left	=> 290,
	-top	=> 540,
);

$main->AddButton(
	-name	=> "unStegButton",
	-text	=> "Прочитать из файла",
	-width	=> 130,
	-height	=> 30,
	-left	=> 650,
	-top	=> 540,
);

$main->Resize(805, 620);
$main->Show();
Win32::GUI::Dialog();

sub Main_Resize {
	my $mw = $main->ScaleWidth();
	my $mh = $main->ScaleHeight();
	# my $lw = $text_e->Width();
	# my $lh = $text_d->Height();

	$text_e->Width(($mw / 2) - 20);
	$text_e->Height($mh - 90);
	$text_d->Left(($mw / 2));
	$text_d->Width(($mw / 2) - 10);
	$text_d->Height($mh - 90);

	return 0;
}