sub getFragSize ($) {
	open (IN, "<:raw", $_[0]);

	sysseek (IN, 34, SEEK_SET);
	sysread (IN, $size, 2);
	my $size=ord(substr($size, 1, 1))+ord(substr($size, 0, 1));

	close IN;

	return $size;
}

sub byteLimitWav ($) {
	my $file = shift;

	return int(((stat($file))[7]-44)/4)-7;
}

sub write2Wav ($$) {
	open (OUT, "+<:raw", $_[1]);

	my $write = '';

	my $size = getFragSize($_[1]);
	my @bin = str2bin($_[0]);
	my @cod = split('', dec2bin(scalar(@bin)/8));

	sysseek (OUT, 44, SEEK_SET);
	for ($i=0; $i < 8; $i++) {
		my $t = '';
		sysread (OUT, $t, 2);
		my @now = byte2bin($t);
		@now[4..7] = @cod[$i*4..$i*4+3];
		$write .= chr (oct ('0b' . join('',@now))) . substr($t, 1, 1);
	}
	for ($i=0; $i<=$#bin; $i+=4) {
		my $t = '';
		sysread (OUT, $t, 2);
		my @now = byte2bin($t);
		@now[4..7] = @bin[$i..$i+3];
		$write .= chr (oct ('0b' . join ('', @now))) . substr($t, 1, 1);
	}
	sysseek (OUT, 44, 0);
	syswrite (OUT, $write);
	close OUT;
}

sub readWav ($) {
	open (READ, '<:raw', $_[0]);

	my $fsize = getFragSize($_[0]);
	my $size = (stat($_[0]))[7]-44;

	my $t = '';
	my $b_text = '';
	my $m_size = 0;
	my $text = '';

	sysseek (READ, 44, SEEK_SET);
	sysread (READ, $t, $size);
	sysseek (READ, 0, 0);
	close READ;

	@text = split ('', $t);

	for ($i=0; $i < 8; $i++) {
		my @here = byte2bin($text[$i*2]);
		$m_size .= join ('', @here[4..7]);
	}

	$m_size = (oct ('0b' . $m_size))*2 + 8;

	for ($i = 8; $i <= $m_size; $i++) {
		my @here = byte2bin($text[$i*2]);
		$b_text .= join('', @here[4..7]);
	}
	$size = length($b_text);
	for ($i = 0; $i <= $size; $i+=8) {
		$text .= chr (oct ('0b' . substr($b_text, $i, 8)));
	}
	sysseek (READ, 0, SEEK_SET);
	close READ;

	return substr($text, 0, -2);
}

1;