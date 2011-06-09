#!/usr/bin/perl -w

use warnings;
use strict;
use Win32::GUI(), qw(	SB_THUMBTRACK SB_LINEDOWN SB_LINEUP
						WS_CAPTION WS_SIZEBOX WS_CHILD
						WS_CLIPCHILDREN WS_EX_CLIENTEDGE RGN_DIFF);
use lib qw(./lib);

require 'bintools.pm'; #loading module for binary op's

require 'wav_steg.pm'; #...module for wav...
require 'bmp_steg.pm'; #and bmp steganorgaphy
require 'crypt.pm';

our $ver = '0.0.2';

my $ChildCount = -1;
my $Window;
my %file;
my %ext;
my %icon;
my @filter=("BMP image files", "*.bmp", "WAV audio files", "*.wav");
my $t;

for (my $i = 0; $i < scalar(@filter)/2; $i++) {
	$t .= "$filter[($i*2+1)];";
}

push (@filter, ("All supported types", $t));

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
	-title  => "KAinS by Utter, ver $ver",
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

$Window->Resize(900, 680);
$Window->Show();
Win32::GUI::Dialog();

sub NewChild {
	my $Child = $Window->{Client}->AddMDIChild (
		-name			=> "Child".++$ChildCount,
		-onActivate		=> sub { print "Activate\n"; },
		-onDeactivate	=> sub { print "Deactivate\n"; },
		-onTerminate	=> sub { print "Terminate\n";},
		-width			=> 800,
		-height			=> 600,
		-minwidth		=> 400,
		-minheight		=> 250,
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
	);

	$Child->AddTimer("TextTimer".$ChildCount, 250);

	$Child->AddTextfield(
		-name	=> "unSteg",
		-font	=> $font,
		-left	=> 400,
		-top	=> 10,
		-width	=> 380,
		-height	=> 490,
		-multiline => 1,
		-vscroll => 1,
		-readonly => 1,
	);

	$Child->AddTextfield(
		-name	=> "txtPass",
		-font	=> $font,
		-password => 1,
		-readonly => 1,
		-top	=> 50,
		-width	=> 140,
		-height	=> 20,
		-prompt	=> "Пароль: ",
	);

	# my $icon{$Child} = new Win32::GUI::Window (
		# -parent      => $Child,
		# -name        => "ChildWin",
		# -pos         => [0, 0],
		# -size        => [200, 200],
		# -popstyle    => WS_CAPTION | WS_SIZEBOX,
		# -pushstyle   => WS_CHILD | WS_CLIPCHILDREN,
		# -pushexstyle => WS_EX_CLIENTEDGE,
		# -class       => $WC,
		# -hscroll     => 1,
		# -vscroll     => 1,
		# -onScroll    => \&Scroll,
		# -onResize    => sub {&Resize($bitmap,@_)},
		# -onPaint     => sub {&Paint($memdc,@_)},
	# );

	$Child->AddCheckbox(
		-name	=> "chkPass",
		-text	=> "Зашифровать сообщение",
		-top	=> 10,
		-onClick=> sub {$Child->{txtPass}->SetReadOnly(($Child->{chkPass}->Checked() ^ 1)) },
	);

	$Child->AddButton(
		-name	=> "btnSteg",
		-text	=> "Записать в файл",
		-width	=> 110,
		-height	=> 30,
		-font	=> $font,
		-onClick=> sub { Steg($Child) },
	);

	$Child->AddButton(
		-name	=> "btnUSteg",
		-text	=> "Прочитать из файла",
		-width	=> 130,
		-height	=> 30,
		-font	=> $font,
		-onClick=> sub { UnSteg($Child) },
	);

	$Child->AddButton(
		-name	=> "btnChangeFile",
		-text	=> "Выбрать другой файл",
		-width	=> 140,
		-height	=> 30,
		-font	=> $font,
		-onClick=> sub { fileSelect($Child) },
	);

	$Child->Change(
		-onResize => \&ChildSize,
	);
	ChildSize($Child);

	while ($file{$Child} !~ '.') {
		fileSelect($Child);
	}

	return 0;
}

sub ChildSize {
	my $self = shift;
	my ($width, $height) = ($self->GetClientRect())[2..3];

	$self->{unSteg}->Left(($width - 150) / 2 + 5);
	$self->{unSteg}->Resize((($width - 150) / 2 - 15), ($height - 60));
	$self->{Steg}->Resize((($width - 150) / 2 - 15), ($height - 60));
	$self->{btnSteg}->Left(($width - 150) / 2 - 110);
	$self->{btnSteg}->Top($height - 40);
	$self->{btnUSteg}->Left($width - 150 - 140);
	$self->{btnUSteg}->Top($height - 40);
	$self->{btnChangeFile}->Left($width - 150);
	$self->{btnChangeFile}->Top($height - 40);
	$self->{chkPass}->Left($width - 150);
	$self->{txtPass}->Left($width - 150);

	return 0;
}

sub getExtension ($) {
	my $file = shift;
	my $i = rindex($file, '.')+1;
	return substr($file, $i);
}

sub fileSelect ($) {
	my $self = shift;
	my $temp = $file{$self};
	$file{$self} = $self->GetOpenFileName(
		-filter =>\@filter,
		-defaultfilter => ((scalar(@filter)/2)-1),
		-filemustexist => 1,
		-pathmustexist => 1,
	);
	if ($file{$self} !~ '.') { $file{$self} = $temp } 
	$file{$self} =~ s|\\|/|g;
	$ext{$self} = ucfirst(getExtension($file{$self}));

	$self->Change(-text => $file{$self},);
	if ($file{$self} =~ '.') { $self->{Steg}->SetLimitText(eval "byteLimit$ext{$self}('$file{$self}')") }
	$self->{Steg}->Text('');
	$self->{unSteg}->Text('');
}

sub Steg ($) {
	my $self = shift;
	my $text = "BCNS".($self->{chkPass}->Checked())."0";
	my $t = ($self->{Steg}->Text());

	if ($self->{chkPass}->Checked()) {
		$t = xcrypt($self->{txtPass}->Text(), $t);
	}
	$text .= $t;

	eval("write2$ext{$self}('$text','$file{$self}')");
}

sub UnSteg ($) {
	my $self = shift;
	if ((eval("isContainer$ext{$self}('$file{$self}')"))[0]) {
		$self->{unSteg}->Text(eval("read$ext{$self}('$file{$self}')"));
	}
	else {
		Win32::GUI::MessageBox($self, "Данный файл не содержит стеганографической информации.\nВы можете записать свою информацию в этот файл или выбрать другой", "Файл не является стеганографическим контейнером", 0x0000)
	}
}	