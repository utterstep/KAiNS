sub dec2bin ($) {
	return unpack("B32", pack("N", shift)) 
}

sub str2bin ($) {
	my $str = shift;
	my @bin = ();
	my @t = split('', shift);
	for (my $i=0; $i < length($str); $i++) {
		push @bin, split ('', sprintf "%08b", ord(substr($str, $i, 1)));
	}
	return @bin;
}

sub byte2bin ($) { 
	return split('', substr(dec2bin(ord(shift)), 24, 8));
}

1;