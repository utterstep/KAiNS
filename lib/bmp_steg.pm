sub byteLimitBmp ($) {
	my $file = shift;
	my $offset = getOffsetBmp($file);

	return int(((stat($file))[7]-$offset)/4)-7;
}

sub getOffsetBmp ($) {
	open (IN, "<:raw", $_[0]);

	sysseek (IN, 10, 0);
	sysread (IN, $offset, 4);
	my $offset=ord(substr($offset, 3, 1))+ord(substr($offset, 2, 1))+ord(substr($offset, 1, 1))+ord(substr($offset, 0, 1));
	sysseek (IN, 0, 0);

	close IN;

	return $offset;
}

sub isContainerBmp ($) { #should return boolean objects (IS_CONTAINER, IS_CRYPTED, IS_FILE_CONTAINER)
	open (READ, '<:raw', $_[0]);

	my $off = getOffsetBmp($_[0]);

	my $t = '';
	my $b_text = '';
	my $m_size = 0;
	my $text = '';

	sysseek (READ, $off, 0);
	sysread (READ, $t, 16+(6*4));
	sysseek (READ, 0, 0);
	close READ;

	my @text = split ('', $t);
	undef $t;

	for ($i=0; $i < 16; $i++) {
		my @here = byte2bin($text[$i]);
		$m_size .= join ('', @here[6..7]);
	}

	my $size = (stat($_[0]))[7]-$off;
	$m_size = (oct ('0b' . $m_size))*4 + 16;

	return (0, 0, 0) if ($m_size > $size);

	for ($i = 16; $i < 40; $i++) {
		my @here = byte2bin($text[$i]);
		$b_text .= join('', @here[6..7]);
	}
	for ($i = 0; $i < 48; $i+=8) {
		$text .= chr (oct ('0b' . substr($b_text, $i, 8)));
	}

	if ($text =~ 'BCNS') {
		return (1, substr($text, 4, 1), substr($text, 5, 1));
	}
	else { return (0, 0, 0) }
}

sub write2Bmp ($$) {
	open (OUT, "+<:raw", $_[1]);

	my $write = '';

	my $off = getOffsetBmp($_[1]);
	sysseek (OUT, $off, 0);
	my @bin = str2bin($_[0]);
	undef $_[0];
	my @cod = split('', dec2bin(scalar(@bin)/8));
	
	for ($i=0; $i < 16; $i++) {
		my $t;
		sysread (OUT, $t, 1);
		my @now = byte2bin($t);
		@now[6..7] = @cod[$i*2..$i*2+1];
		$write .= chr (oct ('0b' . join('',@now)));
	}
	for ($i=0; $i<=$#bin; $i+=2) {
		my $t;
		sysread (OUT, $t, 1);
		my @now = byte2bin($t);
		@now[6..7] = @bin[$i..$i+1];
		undef @bin[$i..$i+1];
		$write .= chr (oct ('0b' . join('',@now)));
	}
	sysseek (OUT, $off, 0);
	syswrite (OUT, $write);
	close OUT;
	undef $write;
	undef @bin;
	
	return 0;
}

sub readBmp ($) {
	open (READ, '<:raw', $_[0]);

	my $off = getOffsetBmp($_[0]);
	my $size = (stat($_[0]))[7]-$off;

	my $t = '';
	my $b_text = '';
	my $m_size = 0;
	my $text = '';

	sysseek (READ, $off, 0);
	sysread (READ, $t, $size--);
	sysseek (READ, 0, 0);
	close READ;

	@text = split ('', $t);
	undef $t;

	for ($i=0; $i < 16; $i++) {
		my @here = byte2bin($text[$i]);
		$m_size .= join ('', @here[6..7]);
	}

	$m_size = (oct ('0b' . $m_size))*4 + 16;

	for ($i = 16; $i < $m_size; $i++) {
		my @here = byte2bin($text[$i]);
		$b_text .= join('', @here[6..7]);
	}
	$size = length($b_text);
	for ($i = 0; $i < $size; $i+=8) {
		$text .= chr (oct ('0b' . substr($b_text, $i, 8)));
	}

	undef @text;
	undef $b_text;

	return substr($text, 6);
}

1;