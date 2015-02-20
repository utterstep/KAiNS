# !/usr/bin/perl -w

use warnings;
use strict;
use Win32::GUI(), qw(	SB_THUMBTRACK SB_LINEDOWN SB_LINEUP
						WS_CAPTION WS_SIZEBOX WS_CHILD
						WS_CLIPCHILDREN WS_EX_CLIENTEDGE RGN_DIFF
						WS_POPUP WS_THICKFRAME WS_EX_TOPMOST);
use lib qw(./lib);
use File::Copy;
use locale;
use Imager;

require 'bintools.pm'; # loading module for binary op's

require 'wav_steg.pm';	# ...module for wav,...
require 'bmp_steg.pm';	# ...bmp...
require 'png_steg.pm';	# ...and png steganography
require 'crypt.pm';		# cryptography is also needed

our $ver = '0.9.0';

# try to load the splash bitmap from the exe that is running
my $splashimage = new Win32::GUI::Bitmap('SPLASH');

# get the dimensions of the bitmap
my ($width,$height) = $splashimage->Info() if defined $splashimage;

# create the splash window
my $splash     = new Win32::GUI::Window (
   -name       => "Splash",
   -text       => "Splash",
   -height     => $height,
   -width      => $width,
   -left       => 100,
   -top        => 100,
   -addstyle   => WS_POPUP,
   -popstyle   => WS_CAPTION | WS_THICKFRAME,
   -addexstyle => WS_EX_TOPMOST
);

# create a label in which the bitmap will be placed
my $bitmap    = $splash->AddLabel(
    -name     => "Bitmap",
    -left     => 0,
    -top      => 0,
    -width    => $width,
    -height   => $height,
    -bitmap   => $splashimage,
);

# center the splash and show it
$splash->Center();
$splash->Show();
# call do events - not Dialog - this will display the window and let us
# build the rest of the application.
Win32::GUI::DoEvents();

my $ChildCount = -1; # count of Child windows
my ($Window, %file, %ext, %icon, $t, $asking, %pass, %file_tc); # some var's
my @filter=("Image files", "*.bmp;*.png", "WAV audio files", "*.wav"); # allowed file formats

my %message = ( # file-info messages
	"000" => "Этот файл не содержит стеганографических данных",
	"100" => "Этот файл содержит текстовое сообщение",
	"101" => "Этот файл содержит в себе другой файл",
	"110" => "Этот файл содержит защищенное паролем текстовое сообщение",
	"111" => "Этот файл содержит в себе зашифрованный файл",
);

for (my $i = 0; $i < scalar(@filter)/2; $i++) { # creating All supported types choice
	$t .= "$filter[($i*2+1)];";
}

push (@filter, ("Все поддреживаемые типы", $t));

my $Menu = Win32::GUI::MakeMenu( # creating menu
	"&Файл"		=> "File",
	"   > &Новый"			=> { -name => "File_New",  -onClick => \&NewChild },
	"   > -"			=> 0,
	"   > Вы&ход"		=> { -name => "File_Exit", -onClick => sub { -1; } },
	"&Окно"	=> "Window",
	"   > К &следующему"		=> { -name => "Next",	-onClick => sub { $Window->{Client}->Next;	 } },
	"   > К &предыдущему"	=> { -name => "Prev",	-onClick => sub { $Window->{Client}->Previous; } },
	"   > -"			=> 0,
	"   > Расположить &горизонтально"	=> { -name => "TileH",   -onClick => sub { $Window->{Client}->Tile(1);  } },
	"&Помощь"		=> "Help",
	"   > О програ&мме"		=> { -name => "About", -onClick => sub { 1; } },
);
##fonts defining
my $font = Win32::GUI::Font->new(
	-size => 10,
);

my $font9 = Win32::GUI::Font->new(
	-size => 9,
);
# creating main window
$Window = new Win32::GUI::MDIFrame (
	-title  => "KainS, ver $ver",
	-minwidth  => 850,
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
sleep(2) if defined $splashimage;

# ... hide the splash and enter the Dialog phase
$splash->Animate(
	-show => 0,
	-activate => 1,
	-animation => 'blend',
	-time => 800,
);

$Window->Show();
Win32::GUI::Maximize($Window);
NewChild();

Win32::GUI::Dialog();

###sub to override default behaviour of "Close" button in password dialog
sub passPrompt_Terminate {
	$dialog->Hide();
	$dialog->{txtPassAsk}->Text('');
	return 0;
}

sub NewChild { # creating "child" window (GUI uses MDI window model)
	my $Child = $Window->{Client}->AddMDIChild (
		-name			=> "Child".++$ChildCount,
		-onActivate		=> sub { print "Activate\n"; }, # for...
		-onDeactivate	=> sub { print "Deactivate\n"; }, # ...debugging...
		-onTerminate	=> sub { print "Terminate\n"; }, # ...purposes
		-width			=> 880,
		-height			=> 600,
	) or die "Child";

	###designing main window###
	$Child->AddLabel(
		-name	=> "lblSteg",
		-text	=> "Введите текст для записи, или откройте текстовый файл\nзатем нажмите \"Записать в контейнер\":",
		-pos	=> [10, 10],
	);

	$Child->AddLabel(
		-name	=> "lblUSteg",
		-text	=> 'Кнопкой "Прочитать из контейнера" можно извлечь Ваше сообщение:',
		-pos	=> [10, 10],
	);

	$Child->AddTextfield(
		-name	=> "Steg",
		-font	=> $font,
		-left	=> 10,
		-top	=> 40,
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
		-top	=> 40,
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
		-width	=> 135,
		-height	=> 30,
		-font	=> $font9,
		-onClick=> sub { Steg($Child, $Child->{Steg}->Text(), 0) },
	);

	$Child->AddButton(
		-name	=> "btnFileSteg",
		-text	=> "Выбрать файл с текстом",
		-width	=> 180,
		-height	=> 30,
		-left	=> 10,
		-font	=> $font,
		-onClick=> sub { File($Child) },
	);

	$Child->AddButton(
		-name	=> "btnUSteg",
		-text	=> "Прочитать из контейнера",
		-width	=> 155,
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
		-text	=> "Для начала работы выберите файл-контейнер",
		-top	=> 30,
		-size	=> [150, 90],
	);

	###for heavens sake that's all design...###

	$Child->Change( # setting resize handler
		-onResize => \&ChildSize,
	);
	ChildSize($Child); # forcing resize to set all elements on their places

	$Child->{btnSteg}->Enable(0); # disabling...
	$Child->{btnFileSteg}->Enable(0); # ...all...
	$Child->{btnUSteg}->Enable(0); # ...controls...
	$Child->{Steg}->Enable(0); # ...before any file being chosen

	Win32::GUI::Maximize($Child); # maximizing "child" window to use all space in "parent"
	fileSelect($Child); # asking for the file

	return 0;
}

sub getExtension ($) { # in: file name, out: file extension
	my $file = shift;
	my $i = rindex($file, '.')+1;
	return substr($file, $i);
}

sub fileSelect ($) { # file select dialog and handlers
	my $self = shift; # getting link on "Child"
	my $temp = $file{$self}; # savin' old file
	Win32::GUI::MessageBox($self, "Пожалуйста, выберите файл-контейнер\n", "Выберите файл", 0x0000|0x0000); # let's say to user what do we want from him
	$file{$self} = $self->GetOpenFileName( # system FileOpen dialog call
		-filter =>\@filter,
		-defaultfilter => ((scalar(@filter)/2)-1),
		-filemustexist => 1,
		-pathmustexist => 1,
	);
	if (!defined($file{$self})) { $file{$self} = $temp } # if nothing was selected - getting back to the old file

	else {
		$file{$self} =~ s|\\|/|g;
		$ext{$self} = ucfirst(lc(getExtension($file{$self}))); # setting "proper" extesion
		$self->Change(-text => $file{$self},); # let's say in name what file we're workin' on
		my $max_l = eval("byteLimit$ext{$self}('$file{$self}')"); # size limit
		my @probe = eval("isContainer$ext{$self}('$file{$self}')"); # getting info about file
		$self->{Steg}->SetLimitText($max_l); # setting limit if textfield
		$self->{lblMaxSize}->Change( -text	=> "В этот файл можно записать информацию, объем которой не превышает: $max_l символов, или ". (int (($max_l-256)/1024)) . " Kb"); # setup of...
		$self->{lblFileInfo}->Change( -text	=> "Вы выбрали файл ".substr($file{$self}, rindex($file{$self}, '/')+1)."\n$message{$probe[0].$probe[1].$probe[2]}", ); # ...info labels
		$self->{btnSteg}->Enable(1); # let's...
		$self->{btnFileSteg}->Enable(1); # ...turn...
		$self->{btnUSteg}->Enable(1); # ...it all...
		$self->{Steg}->Enable(1); # ...ON
		$self->{Steg}->Text(''); # removing...
		$self->{unSteg}->Text(''); # ...old data
	}

	return 0;
}

sub Steg ($$$) {
	my $self = $_[0]; # getting link on "Child"
	my $text = "BCNS".($self->{chkPass}->Checked()).$_[2]; # creating signature
	my $t = $_[1]; # our text

	if ($self->{chkPass}->Checked()) { # crypt if asked for
		$t = xcrypt($self->{txtPass}->Text(), $t);
	}
	$text .= $t; # setting the whole message (signature + text)

	$text =~ s|'|\\'|g; # screening quotes

	my @probe = eval("isContainer$ext{$self}('$file{$self}')"); # getting info about file

	if ($probe[0]) { # if file is already a container
		my $copy = $file{$self}; # creating...
		substr ($copy, rindex ($copy, '.')) = '-copy'; # ...name...
		$copy .= lc(".$ext{$self}"); # ...for the copy
		# asking user's descision
		my $act = Win32::GUI::MessageBox($self, "Файл содержит стеганографическую информацию.\nЗаписать новое сообщение в файл $copy?\n\nПри записи в исходный файл данные, находящиеся в нем сейчас, будут утеряны.", "Файл содержит данные", 0x0003|0x0030);
		if ($act == 6) { # if he decided to ensure existance of old data:
			copy($file{$self},$copy) or die "Copy failed: $!"; # create cope of old file
			eval('write2'.$ext{$self}."('".$text."','".$copy."')"); # write data to the copy
			$file{$self} = $copy; # change file with which we're workin' to new
			$self->Change( -text => $file{$self} ); # renaming our "Child"
			$self->{unSteg}->Text(''); # deleting obsolete UI data
			$self->{lblFileInfo}->Change( -text	=> "Вы выбрали файл ".substr($file{$self}, rindex($file{$self}, '/')+1)."\n$message{$probe[0].$probe[1].$probe[2]}", ); # change label
			Win32::GUI::MessageBox($self, "Ваше сообщение записанно в файл\n$copy", "Данные записаны", 0x0000|0x0000); # signal that everything's OK
		}
		elsif ($act == 7) { # if user doesn't want old data:
			eval('write2'.$ext{$self}."('".$text."','".$file{$self}."')"); # OK, we'll delete it, no problem
			$self->{unSteg}->Text(''); # deleting obsolete UI data
			$self->{lblFileInfo}->Change( -text	=> "Вы выбрали файл ".substr($file{$self}, rindex($file{$self}, '/')+1)."\n$message{$probe[0].$probe[1].$probe[2]}", ); # change label
			Win32::GUI::MessageBox($self, "Ваше сообщение записанно в файл\n$file{$self}", "Данные записаны", 0x0000|0x0000); # signal that everything's OK
		}
		else { 1; } # if cancell - GTFO of here!
	}
	else { # if file is clear - just write everything
		eval('write2'.$ext{$self}."('".$text."','".$file{$self}."')");
		$self->{unSteg}->Text(''); # deleting obsolete UI data
		$self->{lblFileInfo}->Change( -text	=> "Вы выбрали файл ".substr($file{$self}, rindex($file{$self}, '/')+1)."\n$message{$probe[0].$probe[1].$probe[2]}", ); # change label
		Win32::GUI::MessageBox($self, "Ваше сообщение записанно в файл\n$file{$self}", "Данные записаны", 0x0000|0x0000); # signal that everything's OK
	}

	undef $text; # delete unnecsessary data

	return 0;
}

sub UnSteg ($) {
	my $self = shift; # getting link on "Child"
	my @probe = eval("isContainer$ext{$self}('$file{$self}')"); # let's see what's there...
	if ($probe[0]) { # if something is hidden...
		if ($probe[1]) { # ...and crypted...
			$asking = $self; # let's ask user if he knows password
			$dialog->Show();
		}
		else { # else just unsteg
			$self->{unSteg}->Text(eval("read$ext{$self}('$file{$self}')"));
		}
	}
	else { # if file is clear - we'll say it
		Win32::GUI::MessageBox($self, "Данный файл не содержит стеганографической информации.\nВы можете записать свою информацию в этот файл или выбрать другой", "Файл не является стеганографическим контейнером", 0x0000|0x0040)
	}

	return 0;
}

sub Pass { # pass "applying" sub
	$pass{$asking} = $dialog->{txtPassAsk}->Text(); # get the pass
	$dialog->{txtPassAsk}->Text(''); # clear pass prompt field
	my $text = xcrypt($pass{$asking}, eval("read$ext{$asking}('$file{$asking}')")); # unsteg and uncrypt
	$asking->{unSteg}->Text($text); # pushing text in "Child" which's asked for it
	$dialog->Hide(); # go away fugu-fish!

	return 0;
}

sub File { # castrated  "File-steg". Don't want to talk about it.
	my $self = shift;
	my @filt = ("Текстовый файл", "*.txt");
	$file_tc{$self} = $self->GetOpenFileName(
		-filter => \@filt,
		-filemustexist => 1,
		-pathmustexist => 1,
	);
	if ($file_tc{$self} =~ ':') {
		my $ext = ucfirst(lc(getExtension($file{$self})));
		my $max_l = eval("byteLimit$ext{$self}('$file{$self}')");
		if ((stat($file_tc{$self}))[7] <= $max_l-256) {
			open (IN, "<", $file_tc{$self});
			my $text;
			while (<IN>) {
				$text .= "$_\r\n"
			}
			close (IN);
			$self->{Steg}->Text($text);
			undef $file_tc{$self};
			undef $text;
		}
		else {
			Win32::GUI::MessageBox($self, "Файл превышает максимально допустимый размер для данного контейнера\nВы можете записать файл, размером не больше чем ".int(($max_l-256)/1024)."kb.", "Файл слишком большой", 0x0000|0x0030)
		}
	}
}

sub ChildSize { # resizing handler. *CAUTION* full of magic *CAUTION*
	my $self = shift;
	my ($width, $height) = ($self->GetClientRect())[2..3];

	$self->{unSteg}->Left(($width - 150) / 2 + 5);
	$self->{unSteg}->Resize((($width - 150) / 2 - 15), ($height - 90));
	$self->{Steg}->Resize((($width - 150) / 2 - 15), ($height - 150));
	$self->{lblSteg}->Resize((($width - 150) / 2 - 5), 30);
	$self->{lblUSteg}->Resize((($width - 150) / 2 - 5), 20);
	$self->{lblMaxSize}->Left($width - 150);
	$self->{lblMaxSize}->Top($height - 120);
	$self->{lblFileInfo}->Left($width - 150);
	$self->{lblUSteg}->Left(($width - 150) / 2 + 5);
	$self->{btnSteg}->Left(($width - 150) / 2 - 139);
	$self->{btnSteg}->Top($height - 43);
	$self->{btnFileSteg}->Top($height - 95);
	$self->{btnUSteg}->Left($width - 150 - 165);
	$self->{btnUSteg}->Top($height - 40);
	$self->{btnChangeFile}->Left($width - 150);
	$self->{btnChangeFile}->Top($height - 50);
	$self->{chkPass}->Top($height - 60);
	$self->{txtPass}->Top($height - 35);

	return 0;
}
