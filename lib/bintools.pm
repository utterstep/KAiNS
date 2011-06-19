sub dec2bin ($) {
	return unpack("B32", pack("N", shift)) 
}

sub str2bin ($) {
	my $str = shift;
	my @bin = ();
	for (my $i=0; $i < length($str); $i++) {
		push @bin, split ('', sprintf "%08b", ord(substr($str, $i, 1)));
	}
	undef $str;
	return @bin;
}

sub byte2bin ($) { 
	return split('', substr(dec2bin(ord(shift)), 24, 8));
}

1;