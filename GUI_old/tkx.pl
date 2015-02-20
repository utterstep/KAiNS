#!/usr/bin/perl
use Tkx;
use File::Copy;
use utf8;
require 'bmp_steg.pl';

our $PROGNAME = 'Steganographical Suite by VS&SD';
our $VERSION  = '0.1a';

sub make_menu {
    my $mw = shift;

    # отключаем режим открепления меню (подобно в GIMP)
    Tkx::option_add( '*tearOff', 0 );

    # в зависимости от ОС, идентификатор кнопки Ctrl/Control может меняться
    my $control = ($^O eq "darwin") ? "Command"  : "Control";
    my $ctrl    = ($^O eq "darwin") ? "Command-" : "Ctrl+";

    # верхние уровни
    my $menu = $mw->new_menu();
    my $menu_file = $menu->new_menu();
    my $menu_help = $menu->new_menu();

    $menu->add_cascade(
        -label => 'File',
        -menu  => $menu_file,
    );

    $menu->add_cascade(
        -label => 'Help',
        -menu  => $menu_help,
    );

    # Добавляем элементы в меню File
    $menu_file->add_command(
        -label => 'Quit',
        -command => sub { $mw->g_destroy(); },
    );

    # меню Help
    $menu_help->add_command(
        -label => 'About...',
        -command => sub {
            Tkx::tk___messageBox(
                -title => 'About...',
                -message => "$PROGNAME\n$VERSION",
            );
        },
    );

    # возвращаем меню
    return $menu;
}

my $mw = Tkx::widget->new( '.' );
$mw->g_wm_minsize(700,410);
my $frame_enc = $mw->new_ttk__labelframe(-text => 'Write to BMP');

my $text_enc = $mw->new_tk__text( -height => 40, -wrap => 'word');
my $text_dec = $mw->new_tk__text( -height => 40, -state => 'disabled', -wrap => 'word');

my $button_wr = $mw->new_ttk__button(-text => 'Запись в BMP');
my $button_get = $mw->new_ttk__button(-text => 'Прочитать BMP');
my $button_choose_wr = $mw->new_ttk__button(-text => 'Выберите файл-прототип');
my $button_choose_rd = $mw->new_ttk__button(-text => 'Выберите файл-контейнер');

$button_wr->configure(
    -command => sub {
		my $t = $text_enc->get('1.0', 'end');
		print $t;
		if (($in ne '') && (length ($t)) <= $in_size) {
			copy($in,"out.bmp") or die "Copy failed: $!";
			write2Bmp ($t, "out.bmp");
			Tkx::tk___messageBox(
                -title => 'Done!',
                -message => "Your text is now in out.bmp",
            )
		}
		elsif (length ($t) <= $in_size) {
			Tkx::tk___messageBox(
                -title => 'Error',
				-icon => 'error',
                -message => "You can write not more than $in_size symbols\nYou entered ".length ($t),
            )
		}
		else {
			Tkx::tk___messageBox(
                -title => 'Error',
				-icon => 'error',
                -message => "You hadn't chosen any file!",
            )
		}
    },
);

$button_get->configure(
    -command => sub {
		if ($get ne '') {
			my $text = '';
			$text = readBmp ($get);
#			$progress -> start;
			$text_dec -> configure (-state => 'normal');
			$text_dec -> delete ('1.0', 'end');
			$text_dec -> insert ('1.0', $text);
			$text_dec -> configure (-state => 'disabled');
		}
		else {
			Tkx::tk___messageBox(
                -title => 'Error',
				-icon => 'error',
                -message => "You hadn't chosen any file!",
            )
		}
    },
);

$button_choose_wr->configure(
    -command => sub {
		$in = Tkx::tk___getOpenFile(-defaultextension => '.bmp', -filetypes => '{{Bitmap Images} {.bmp .BMP}}');
		$in_size = int (((stat($in))[7] - getOffsetBmp($in))/8);
		}
);

$button_choose_rd->configure(
    -command => sub {
		$get = Tkx::tk___getOpenFile(-filetypes => '{{Bitmap Images} {.bmp .BMP}}');
		}
);


# my $progress = $mw->new_ttk__progressbar(-orient => 'horizontal', -length => 200, -mode => 'indeterminate');

my $frame = $mw->new_ttk__frame();

my $l_in = $mw->new_ttk__label(-justify => 'right', -textvariable => \$in);
my $l_in_size = $mw->new_ttk__label(-justify => 'right', -textvariable => \$in_size);
my $l_in_s_txt = $mw->new_ttk__label(-justify => 'right', -text => 'Максимальное доступное кол-во симолов для этого файла:');
my $l_out = $mw->new_ttk__label(-justify => 'left', -textvariable => \$get);

Tkx::grid($button_choose_wr, -sticky => 'w', -row => 0, -column => 0, -padx => 10, -pady => 0);
Tkx::grid($button_choose_rd, -sticky => 'w', -row => 0, -column => 1, -padx => 10, -pady => 0);
Tkx::grid($l_in, -sticky => 'e', -row => 0, -column => 0, -padx => 10, -pady => 0);
Tkx::grid($l_out, -sticky => 'e', -row => 0, -column => 1, -padx => 10, -pady => 0);
Tkx::grid($l_in_size, -sticky => 'e', -row => 1, -column => 0, -padx => 10, -pady => 0);
Tkx::grid($l_in_s_txt, -sticky => 'e', -row => 1, -column => 0, -padx => 80, -pady => 0);
Tkx::grid($button_wr, -sticky => 'e', -row => 3, -column => 0, -padx => 10, -pady => 10);
Tkx::grid($button_get, -sticky => 'e', -row => 3, -column => 1, -padx => 10, -pady => 10);

Tkx::grid($text_enc, -row => 2, -column => 0, -padx => 10, -pady => 10);
Tkx::grid($text_dec, -row => 2, -column => 1, -padx => 10, -pady => 10);

#Tkx::grid($progress, -sticky => 'e', -row => 3, -column => 1, -padx => 10, -pady => 10);

$mw->g_grid_columnconfigure( 0, -weight => 1 );
$mw->g_grid_columnconfigure( 1, -weight => 1 );
$mw->g_grid_rowconfigure( 0, -weight => 1, -minsize => 35 );
$mw->g_grid_rowconfigure( 1, -weight => 1, -minsize => 35 );
$mw->g_grid_rowconfigure( 2, -weight => 1, -minsize => 300 );
$mw->g_wm_title( 'BC&S' );

$mw->configure( -menu => make_menu( $mw ) );

# запускаем основной цикл
Tkx::MainLoop();
