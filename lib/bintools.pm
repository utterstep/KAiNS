sub dec2bin ($) { #convert decimai number into 32-bit representation
	return unpack("B32", pack("N", shift))
}

sub str2bin ($) { #convert string into array of bits, 1 symbol = 8 bits = 1 byte
	my $str = shift;
	my @bin = ();
	for (my $i=0; $i < length($str); $i++) { #magic. if U want to ask me, WHAT THE
		push @bin, split ('', sprintf "%08b", ord(substr($str, $i, 1))); #HELL ARE
	} #YOU DOING, MAN??? just write here: 8uk.8ak[at]gmail.com
	undef $str;
	return @bin;
}

sub byte2bin ($) { #convert symbol into array of bits
	return split('', substr(dec2bin(ord(shift)), 24, 8));
}

1;
