sub byteLimitBmp ($) { #how much can we put here?
	my $file = shift;
	my $offset = getOffsetBmp($file); # -offset

	return int(((stat($file))[7]-$offset)/4)-7; #so the answer is: (filesize minus offset) divided by four, and minus signature size
}

sub getOffsetBmp ($) { #let's get the offset
	open (IN, "<:raw", $_[0]);

	sysseek (IN, 10, 0);
	sysread (IN, $offset, 4);
	my $offset=ord(substr($offset, 3, 1))+ord(substr($offset, 2, 1))+ord(substr($offset, 1, 1))+ord(substr($offset, 0, 1)); #crap, but works in 99%
	sysseek (IN, 0, 0);

	close IN;

	return $offset;
}

sub isContainerBmp ($) { #should return boolean objects (IS_CONTAINER, IS_CRYPTED, IS_FILE_CONTAINER)
	open (READ, '<:raw', $_[0]); #open file

	my $off = getOffsetBmp($_[0]);

	my $t = '';
	my $b_text = '';
	my $m_size = 0;
	my $text = '';

	sysseek (READ, $off, 0);
	sysread (READ, $t, 16+(6*4)); #all we need is here
	sysseek (READ, 0, 0);
	close READ; #close file

	my @text = split ('', $t);
	undef $t; #i don't wanna say that it'll help...

	for ($i=0; $i < 16; $i++) { #assembling message size
		my @here = byte2bin($text[$i]); 
		$m_size .= join ('', @here[6..7]);
	}

	my $size = (stat($_[0]))[7]-$off;
	$m_size = (oct ('0b' . $m_size))*4 + 16; #converting it in 2bit-blocks

	return (0, 0, 0) if ($m_size > $size); #that's no good

	for ($i = 16; $i < 40; $i++) { #assembling signature
		my @here = byte2bin($text[$i]);
		$b_text .= join('', @here[6..7]);
	}
	for ($i = 0; $i < 48; $i+=8) {
		$text .= chr (oct ('0b' . substr($b_text, $i, 8)));
	}

	if ($text =~ 'BCNS') { #if there is our singature - ...
		return (1, substr($text, 4, 1), substr($text, 5, 1)); #...return all we can say
	}
	else { return (0, 0, 0) } #else - sorry
}

sub write2Bmp ($$) { #okay, let's write a little
	open (OUT, "+<:raw", $_[1]); #open yor workbook

	my $write = '';

	my $off = getOffsetBmp($_[1]); #don't touch fileheader!
	sysseek (OUT, $off, 0); #go, no, run away from it!
	my @bin = str2bin($_[0]); #convert message
	my @cod = split('', dec2bin(scalar(@bin)/8)); #how long it is?

	###now we're writing in temporary variable $write###
	for ($i=0; $i < 16; $i++) { #firstly say to the reader how long will be your speech
		my $t;
		sysread (OUT, $t, 1);
		my @now = byte2bin($t);
		@now[6..7] = @cod[$i*2..$i*2+1];
		$write .= chr (oct ('0b' . join('',@now)));
	}
	for ($i=0; $i<=$#bin; $i+=2) { #and now say all
		my $t;
		sysread (OUT, $t, 1);
		my @now = byte2bin($t);
		@now[6..7] = @bin[$i..$i+1];
		undef @bin[$i..$i+1];
		$write .= chr (oct ('0b' . join('',@now)));
	}
	
	###now we'll write to file directly###
	sysseek (OUT, $off, 0);
	syswrite (OUT, $write);
	close OUT;
	undef $write;
	undef @bin;
	
	return 0;
}

sub readBmp ($) { #let's read
	open (READ, '<:raw', $_[0]); #open file

	my $off = getOffsetBmp($_[0]);
	my $size = (stat($_[0]))[7]-$off;

	my $t = '';
	my $b_text = '';
	my $m_size = 0;
	my $text = '';

	sysseek (READ, $off, 0); #skip fileheaders
	sysread (READ, $t, $size--); #read least of file to the memory
	sysseek (READ, 0, 0);
	close READ; #close file

	@text = split ('', $t);
	undef $t;

	for ($i=0; $i < 16; $i++) { #getting 32-bit number, sayin' about message size
		my @here = byte2bin($text[$i]);
		$m_size .= join ('', @here[6..7]);
	}

	$m_size = (oct ('0b' . $m_size))*4 + 16; #conert size in 2bit-blocks

	for ($i = 16; $i < $m_size; $i++) { #read this ammount of data
		my @here = byte2bin($text[$i]);
		$b_text .= join('', @here[6..7]);
	}
	$size = length($b_text);
	for ($i = 0; $i < $size; $i+=8) { #convert it to message back
		$text .= chr (oct ('0b' . substr($b_text, $i, 8)));
	}

	undef @text;
	undef $b_text;

	return substr($text, 6); #return all except signature
}

1;