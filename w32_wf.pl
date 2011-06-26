#!/usr/bin/perl -w

use warnings;
use strict;
use Win32::GUI(), qw(	SB_THUMBTRACK SB_LINEDOWN SB_LINEUP
						WS_CAPTION WS_SIZEBOX WS_CHILD
						WS_CLIPCHILDREN WS_EX_CLIENTEDGE RGN_DIFF);
use lib qw(./lib);
use File::Copy;
use locale;
use Imager;

require 'bintools.pm'; #loading module for binary op's

require 'wav_steg.pm'; #...module for wav,...
require 'bmp_steg.pm'; #...bmp...
require 'png_steg.pm'; #...and png steganography
require 'crypt.pm';

our $ver = '0.2.2';

my $ChildCount = -1;
my ($Window, %file, %ext, %icon, $t, $asking, %pass, %file_tc);
my @filter=("Image files", "*.bmp;*.png", "WAV audio files", "*.wav");

my %message = (
	"000" => "Этот файл не содержит стеганографических данных",
	"100" => "Этот файл содержит текстовое сообщение",
	"101" => "Этот файл содержит в себе другой файл",
	"110" => "Этот файл содержит защищенное паролем текстовое сообщение",
	"111" => "Этот файл содержит в себе зашифрованный файл",
);

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
	# "   > &Cascade"		=> { -name => "Cascade", -onClick => sub { $Window->{Client}->Cascade(); 0; } },
	"   > Tile &Horizontally"	=> { -name => "TileH",   -onClick => sub { $Window->{Client}->Tile(1);  } },
	# "   > Tile &Vertically"		=> { -name => "TileV",   -onClick => sub { $Window->{Client}->Tile(0);  } },
	"&Help"		=> "Help",
	"   > &About "		=> { -name => "About", -onClick => sub { 1; } },
);

my $font = Win32::GUI::Font->new(
	-size => 10,
);

my $font9 = Win32::GUI::Font->new(
	-size => 9,
); 

$Window = new Win32::GUI::MDIFrame (
	-title  => "KAinS by Utter, ver $ver",
	-minwidth  => 800,
	-minheight => 600,
	-name   => "Main",
	-menu   => $Menu,
	-pos	=> [200, 200]
) or die "Window"; 

$Window->AddMDIClient(
	-name	   => "Client",
	-firstchild => 100,
	-windowmenu => $Menu->{Window}->{-handle},
) or die "Client";

#######password input window#######

my $dialog = Win32::GUI::DialogBox->new(
	-name		=> "passPrompt",
	-text		=> "Введите пароль",
	-size		=> [205, 170],
	-topmost	=> 1,
	-hashelp	=> 0,
	-pos		=> [500, 500],
);

$dialog->AddTextfield(
	-name	=> "txtPassAsk",
	-font	=> $font,
	-password => 1,
	-left	=> 50,
	-top	=> 10,
	-width	=> 145,
	-height	=> 23,
	-prompt	=> ["Пароль:", -45],
);

$dialog->AddButton(
	-name	=> "btnPass",
	-text	=> "Расшифровать сообщение",
	-width	=> 200,
	-height	=> 30,
	-top	=> 50,
	-font	=> $font,
	-onClick=> \&Pass,
	-default=> 1,
	-tabstop=> 1,
);

$dialog->AddLabel(
	-name	=> 'lblPassNote',
	-text	=> 'Примечание: при вводе неверного пароля вы получите неверное сообщение. Ваш К.О.',
	-sunken => 1,
	-pos	=> [1, 83],
	-size	=> [195, 70],
	-align	=> 'center',
);

$Window->Resize(900, 680);
$Window->Show();
NewChild();
Win32::GUI::Dialog();

sub passPrompt_Terminate {
	$dialog->Hide();
	return 0;
}

sub NewChild {
	my $Child = $Window->{Client}->AddMDIChild (
		-name			=> "Child".++$ChildCount,
		-onActivate		=> sub { print "Activate\n"; },
		-onDeactivate	=> sub { print "Deactivate\n"; },
		-onTerminate	=> sub { print "Terminate\n"; },
		-width			=> 880,
		-height			=> 600,
	) or die "Child";
	
	$Child->AddLabel(
		-name	=> "lblSteg",
		-text	=> 'Введите текст для записи, затем нажмите "Записать в файл":',
		-pos	=> [10, 10],
	);
	
	$Child->AddLabel(
		-name	=> "lblUSteg",
		-text	=> 'Кнопкой "Прочитать из файла" можно извлечь Ваше сообщение:',
		-pos	=> [10, 10],
	);
	
	$Child->AddTextfield(
		-name	=> "Steg",
		-font	=> $font,
		-left	=> 10,
		-top	=> 30,
		-width	=> 380,
		-height	=> 450,
		-multiline => 1,
		-vscroll => 1,
	);
	
	# $Child->AddTimer("TextTimer".$ChildCount, 250);

	$Child->AddTextfield(
		-name	=> "unSteg",
		-font	=> $font,
		-left	=> 400,
		-top	=> 30,
		-width	=> 380,
		-height	=> 450,
		-multiline => 1,
		-vscroll => 1,
		-readonly => 1,
	);

	$Child->AddTextfield(
		-name	=> "txtPass",
		-font	=> $font,
		-password => 1,
		-disabled => 1,
		-left	=> 10,
		-width	=> 140,
		-height	=> 23,
	);

	$Child->AddCheckbox(
		-name	=> "chkPass",
		-text	=> "Зашифровать сообщение. Пароль:",
		-left	=> 13,
		-onClick=> sub {$Child->{txtPass}->Enable($Child->{chkPass}->Checked()) },
	);

	$Child->AddButton(
		-name	=> "btnSteg",
		-text	=> "Записать в контейнер",
		-width	=> 125,
		-height	=> 30,
		-font	=> $font9,
		-onClick=> sub { Steg($Child, $Child->{Steg}->Text(), 0) },
	);

	$Child->AddButton(
		-name	=> "btnFileSteg",
		-text	=> "Записать файл в контейнер",
		-width	=> 110,
		-height	=> 30,
		-font	=> $font,
		-onClick=> sub { File($Child) },
	);
	
	$Child->AddButton(
		-name	=> "btnUSteg",
		-text	=> "Прочитать из контейнера",
		-width	=> 145,
		-height	=> 30,
		-font	=> $font9,
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
	
	$Child->AddLabel(
		-name	=> "lblMaxSize",
		-top	=> 100,
		-size	=> [150, 60]		
	);
	
	$Child->AddLabel(
		-name	=> "lblFileInfo",
		-top	=> 30,
		-size	=> [150, 90],
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
	$ext{$self} = ucfirst(lc(getExtension($file{$self})));

	$self->Change(-text => $file{$self},);
	my $max_l = eval("byteLimit$ext{$self}('$file{$self}')");
	my @probe = eval("isContainer$ext{$self}('$file{$self}')");
	if ($file{$self} =~ '.') { 
		$self->{Steg}->SetLimitText($max_l);
		$self->{lblMaxSize}->Change( -text	=> "В этот файл можно записать информацию, объем которой не превышает: $max_l символов, или ". (int (($max_l-256)/1024)) . " Kb");
		$self->{lblFileInfo}->Change( -text	=> "Вы выбрали файл ".substr($file{$self}, rindex($file{$self}, '/')+1)."\n$message{$probe[0].$probe[1].$probe[2]}", );
	}
	$self->{Steg}->Text('');
	$self->{unSteg}->Text('');
	
	return 0;
}

sub Steg ($$$) {
	my $self = $_[0];
	my $text = "BCNS".($self->{chkPass}->Checked()).$_[2];
	my $t = $_[1];

	if ($self->{chkPass}->Checked()) {
		$t = xcrypt($self->{txtPass}->Text(), $t);
	}
	$text .= $t;
	
	$text =~ s|'|\\'|g;
	
	my @probe = eval("isContainer$ext{$self}('$file{$self}')");

	if ($probe[0]) {
		my $copy = $file{$self};
		substr ($copy, rindex ($copy, '.')) = '-copy';
		$copy .= lc(".$ext{$self}");
		my $act = Win32::GUI::MessageBox($self, "Файл содержит стеганографическую информацию.\nЗаписать новое сообщение в файл $copy?\n\nПри записи в исходный файл данные, находящиеся в нем сейчас, будут утеряны.", "Файл содержит данные", 0x0003|0x0030);
		if ($act == 6) { 
			copy($file{$self},$copy) or die "Copy failed: $!";
			eval('write2'.$ext{$self}."('".$text."','".$copy."')");
			$file{$self} = $copy;
			$self->Change( -text => $file{$self} );
		}
		elsif ($act == 7) {
			eval('write2'.$ext{$self}."('".$text."','".$file{$self}."')");
		}
		else { 1; }
	}
	else { eval('write2'.$ext{$self}."('".$text."','".$file{$self}."')"); }
	
	undef $text;
	
	$self->{lblFileInfo}->Change( -text	=> "Вы выбрали файл ".substr($file{$self}, rindex($file{$self}, '/')+1)."\n$message{$probe[0].$probe[1].$probe[2]}", );
	$self->{unSteg}->Text('');
	
	return 0;
}

sub UnSteg ($) {
	my $self = shift;
	my @probe = eval("isContainer$ext{$self}('$file{$self}')");
	if ($probe[0]) {
		if ($probe[1]) {
			$asking = $self;
			$dialog->Show();
		}
		else {
			if ($probe[2]) {
				my $temp = eval("read$ext{$self}('$file{$self}')");
				my $i = index($temp, "\n");
				my $name = substr ($temp, 0, $i);
				my $file = substr ($temp, $i);
				my $act = Win32::GUI::MessageBox($self, "В данном контейнере содержится файл $name.\nРаспаковать его в рабочую папку данной программы?", "Контейнер содержит файл", 0x0004|0x0020);
				if ($act == 6) {
					open (OUT, '>:raw', $name);
					syswrite (OUT, $file);
					close OUT;
					Win32::GUI::MessageBox($self, "Файл распакован в $ENV{PWD}/$name", "Записано", 0x0000|0x0030);
				}
			}
			else {
				$self->{unSteg}->Text(eval("read$ext{$self}('$file{$self}')"));
			}
		}
	}
	else {
		Win32::GUI::MessageBox($self, "Данный файл не содержит стеганографической информации.\nВы можете записать свою информацию в этот файл или выбрать другой", "Файл не является стеганографическим контейнером", 0x0000|0x0040)
	}
	
	return 0;
}

sub Pass {
	$pass{$asking} = $dialog->{txtPassAsk}->Text();
	$dialog->{txtPassAsk}->Text('');
	my $text = xcrypt($pass{$asking}, eval("read$ext{$asking}('$file{$asking}')"));
	$asking->{unSteg}->Text($text);
	$dialog->Hide();
	
	return 0;
}

sub File {
	my $self = shift;
	$file_tc{$self} = $self->GetOpenFileName(
		-filter => \("Текстовый файл", "*.txt"),
		-filemustexist => 1,
		-pathmustexist => 1,
	);
	if ($file_tc{$self} =~ ':') {
		my $ext = ucfirst(lc(getExtension($file{$self})));
		my $max_l = eval("byteLimit$ext{$self}('$file{$self}')");
		if ((stat($file_tc{$self}))[7] <= $max_l-256) {
			$ext = ucfirst(lc(getExtension($file_tc{$self})));
			if ($ext eq 'Txt') {
				open (IN, "<", $file_tc{$self});
				my $text;
				while (<IN>) {
					$text .= "$_\n"
				}
				close (IN);
				$self->{Steg}->Text($text);
				undef $file_tc{$self};
			}
		}
		else {
			Win32::GUI::MessageBox($self, "Файл превышает максимально допустимый размер для данного контейнера\nВы можете записать файл, размером не больше чем ".int(($max_l-256)/1024)."kb.", "Файл слишком большой", 0x0000|0x0030)
		}
	}
}

sub ChildSize {
	my $self = shift;
	my ($width, $height) = ($self->GetClientRect())[2..3];

	$self->{unSteg}->Left(($width - 150) / 2 + 5);
	$self->{unSteg}->Resize((($width - 150) / 2 - 15), ($height - 80));
	$self->{Steg}->Resize((($width - 150) / 2 - 15), ($height - 140));
	$self->{lblSteg}->Resize((($width - 150) / 2 - 5), 20);
	$self->{lblUSteg}->Resize((($width - 150) / 2 - 5), 20);
	$self->{lblMaxSize}->Left($width - 150);
	$self->{lblMaxSize}->Top($height - 120);
	$self->{lblFileInfo}->Left($width - 150);
	$self->{lblUSteg}->Left(($width - 150) / 2 + 5);
	$self->{btnSteg}->Left(($width - 150) / 2 - 129);
	$self->{btnSteg}->Top($height - 43);
	$self->{btnFileSteg}->Top($height - 43);
	$self->{btnUSteg}->Left($width - 150 - 155);
	$self->{btnUSteg}->Top($height - 40);
	$self->{btnChangeFile}->Left($width - 150);
	$self->{btnChangeFile}->Top($height - 50);
	$self->{chkPass}->Top($height - 60);
	$self->{txtPass}->Top($height - 35);

	return 0;
}