sub byteLimitWav ($) { #how much can we put here?
	my $file = shift;

	return int(((stat($file))[7]-44)/4)-7;#so the answer is: (filesize minus offset) divided by four, and minus signature size
}

sub getFragSize ($) { #it's here but unnescessary
	open (IN, "<:raw", $_[0]);

	sysseek (IN, 34, 0);
	sysread (IN, $size, 2);
	my $size=ord(substr($size, 1, 1))+ord(substr($size, 0, 1));

	close IN;

	return $size;
}

sub isContainerWav ($) { #should return boolean objects (IS_CONTAINER, IS_CRYPTED, IS_FILE_CONTAINER)
	open (READ, '<:raw', $_[0]); #open file

	my $t = '';
	my $b_text = '';
	my $m_size = 0;
	my $text = '';

	sysseek (READ, 44, 0);
	sysread (READ, $t, 8+(6*8)); #all we need is here
	sysseek (READ, 0, 0);
	close READ; #close file

	my @text = split ('', $t);
	undef $t;

	for ($i=0; $i < 8; $i++) { #assembling message size
		my @here = byte2bin($text[$i*2]);
		$m_size .= join ('', @here[4..7]);
	}

	my $size = (stat($_[0]))[7]-44;
	$m_size = (oct ('0b' . $m_size))*2 + 8; #converting it in 2bit-blocks
	
	return (0, 0, 0) if ($m_size > $size); #that's no good

	for ($i = 8; $i < 20; $i++) { #assembling signature
		my @here = byte2bin($text[$i*2]);
		$b_text .= join('', @here[4..7]);
	}
	for ($i = 0; $i < 48; $i+=8) {
		$text .= chr (oct ('0b' . substr($b_text, $i, 8)));
	}

	if ($text =~ 'BCNS') { #if there is our singature - ...
		return (1, substr($text, 4, 1), substr($text, 5, 1)); #...return all we can say
	}
	else { return (0, 0, 0) } #else - sorry
}

sub write2Wav ($$) { #okay, let's write a little
	open (OUT, "+<:raw", $_[1]); #open yor workbook

	my $write = '';

	my $size = getFragSize($_[1]);
	my @bin = str2bin($_[0]); #convert message
	my @cod = split('', dec2bin(scalar(@bin)/8)); #how long it is?

	###now we're writing in temporary variable $write###
	sysseek (OUT, 44, 0);
	for ($i=0; $i < 8; $i++) { #firstly say to the reader how long will be your speech
		my $t;
		sysread (OUT, $t, 2);
		my @now = byte2bin($t);
		@now[4..7] = @cod[$i*4..$i*4+3];
		$write .= chr (oct ('0b' . join('',@now))) . substr($t, 1, 1);
	}
	for ($i=0; $i<=$#bin; $i+=4) { #and now say all
		my $t;
		sysread (OUT, $t, 2);
		my @now = byte2bin($t);
		@now[4..7] = @bin[$i..$i+3];
		$write .= chr (oct ('0b' . join ('', @now))) . substr($t, 1, 1);
	}
	
	###now we'll write to file directly###
	sysseek (OUT, 44, 0);
	syswrite (OUT, $write);
	close OUT;
	undef @bin;
	undef $write;

	return 0;
}

sub readWav ($) { #let's read
	open (READ, '<:raw', $_[0]); #open file

	my $fsize = getFragSize($_[0]);
	my $size = (stat($_[0]))[7]-44;

	my $t = '';
	my $b_text = '';
	my $m_size = 0;
	my $text = '';

	sysseek (READ, 44, 0); #skip fileheaders
	sysread (READ, $t, $size); #read least of file to the memory
	sysseek (READ, 0, 0);
	close READ; #close file

	@text = split ('', $t);
	undef $t;

	for ($i=0; $i < 8; $i++) { #getting 32-bit number, sayin' about message size
		my @here = byte2bin($text[$i*2]);
		$m_size .= join ('', @here[4..7]);
	}

	$m_size = (oct ('0b' . $m_size))*2 + 8; #conert size in 2bit-blocks

	for ($i = 8; $i < $m_size; $i++) {  #read this ammount of data
		my @here = byte2bin($text[$i*2]);
		$b_text .= join('', @here[4..7]);
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