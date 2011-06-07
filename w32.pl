#!/usr/bin/perl -w

use warnings;
use strict;
use Win32::GUI();
use lib qw(./lib);

require 'bintools.pm'; #loading module for binary op's

require 'wav_steg.pm'; #...module for wav...
require 'bmp_steg.pm'; #and bmp steganorgaphy

our $ver = '0.0.2';

my $ChildCount = -1;
my $Window;
my %file;
my @filter=("BMP image files", "*.bmp", "WAV audio files", "*.wav");
my $def_f;

for (my $i = 0; $i < scalar(@filter)/2; $i++) {
	$def_f .= "$filter[($i*2+1)];";
}

push (@filter, ("All supported types", $def_f));

$def_f = ((scalar(@filter)/2)-1);

my $Menu = Win32::GUI::MakeMenu(
	"&File"		=> "File",
	"   > &New"			=> { -name => "File_New",  -onClick => \&NewChild },
	"   > -"			=> 0,
	"   > E&xit"		=> { -name => "File_Exit", -onClick => sub { -1; } },
	"&Window"	=> "Window",
	"   > &Next"		=> { -name => "Next",	-onClick => sub { $Window->{Client}->Next;	 } },
	"   > &Previous"	=> { -name => "Prev",	-onClick => sub { $Window->{Client}->Previous; } },
	"   > -"			=> 0,
	"   > &Cascade"		=> { -name => "Cascade", -onClick => sub { $Window->{Client}->Cascade(); 0; } },
	"   > Tile &Horizontally"	=> { -name => "TileH",   -onClick => sub { $Window->{Client}->Tile(1);  } },
	"   > Tile &Vertically"		=> { -name => "TileV",   -onClick => sub { $Window->{Client}->Tile(0);  } },
	"&Help"		=> "Help",
	"   > &About "		=> { -name => "About", -onClick => sub { 1; } },
);

my $font = Win32::GUI::Font->new(
	-size => 10,
); 

$Window = new Win32::GUI::MDIFrame (
	-title  => "KAinS by Utter, ver$ver",
	-minwidth  => 800,
	-minheight => 600,
	-name   => "Main",
	-menu   => $Menu,
) or die "Window"; 

$Window->AddMDIClient(
	-name	   => "Client",
	-firstchild => 100,
	-windowmenu => $Menu->{Window}->{-handle},
) or die "Client";

$Window->Resize(805, 620);
$Window->Show();
Win32::GUI::Dialog();

sub NewChild {
	my $Child = $Window->{Client}->AddMDIChild (
		-name			=> "Child".++$ChildCount,
		-onActivate		=> sub { print "Activate\n"; },
		-onDeactivate		=> sub { print "Deactivate\n"; },
		-onTerminate		=> sub { print "Terminate\n";},
	) or die "Child";

	$Child->AddTextfield(
		-name	=> "Steg",
		-font	=> $font,
		-left	=> 10,
		-top	=> 10,
		-width	=> 380,
		-height	=> 490,
		-multiline => 1,
		-vscroll=> 1,
		-onChange => \&Text
	);

	$Child->AddTextfield(
		-name	=> "UnSteg",
		-font	=> $font,
		-left	=> 400,
		-top	=> 10,
		-width	=> 380,
		-height	=> 490,
		-multiline => 1,
		-vscroll=> 1,
		-readonly=> 1,
	);

	$Child->AddButton(
		-name	=> "StegBut",
		-text	=> "Записать в файл",
		-width	=> 110,
		-height	=> 30,
		-font	=> $font,
	);

	$Child->AddButton(
		-name	=> "uStegBut",
		-text	=> "Прочитать из файла",
		-width	=> 130,
		-height	=> 30,
		-font	=> $font,
	);

	# Force a resize.
	$Child->Change(-onResize => \&ChildSize, );
	ChildSize($Child);

	while (!$file{$Child}) {
		$file{$Child} = $Child->GetOpenFileName(
		-filter =>\@filter,
		-difaultfilter => 2,
		-filemustexist => 1,
		-pathmustexist => 1,
		);
	}

	return 0;
}

sub Text {
	my $self = shift;
	print $self->GetLineCount();

	return 0;
}

sub ChildSize {
	my $self = shift;
	my ($width, $height) = ($self->GetClientRect())[2..3];

	$self->{UnSteg}->Left(($width / 2) + 5);
	$self->{UnSteg}->Resize((($width / 2) - 15), ($height - 60));
	$self->{Steg}->Resize((($width / 2) - 15), ($height - 60));
	$self->{StegBut}->Left(($width / 2) - 110);
	$self->{StegBut}->Top($height - 40);
	$self->{uStegBut}->Left($width - 140);
	$self->{uStegBut}->Top($height - 40);

	return 0;
}