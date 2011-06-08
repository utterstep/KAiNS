sub dec2bin ($) {
	return unpack("B32", pack("N", shift)) 
}

sub str2bin ($) {
	my $bin = '';
	my @t = split('', shift);
	for (my $i=0; $i <= $#t; $i++) {
		$bin .= substr(dec2bin(ord($t[$i])), 24, 8);
	}
	return split('', $bin);
}

sub byte2bin ($) { 
	return split('', substr(dec2bin(ord(shift)), 24, 8));
}

1;