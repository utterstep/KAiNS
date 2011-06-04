sub str2bin ($) {
	my @bin = ();
	my $str = $_[0];
	for (my $i=0; $i < length($str); $i++) {
		@bin = (@bin, split ('', sprintf "%08b", ord(substr($str, $i, 1))));
	}
	return @bin;
}

sub getFragSize ($) {
	open (IN, "<:raw", $_[0]);

	sysseek (IN, 34, SEEK_SET);
	sysread (IN, $size, 2);
	my $size=ord(substr($size, 1, 1))+ord(substr($size, 0, 1));
	
	close IN;
	
	return $size;
}

sub write2Wav ($$) {
	open (OUT, "+<:raw", $_[1]);
	
	my $write = '';
	
	my $size = getFragSize($_[1]);
	my @bin = str2bin($_[0]);
	
	sysseek (OUT, 44, SEEK_SET);
	for ($i=0; $i<=$#bin; $i+=4) {
		my $t = '';
		sysread (OUT, $t, 2);
		my @now = str2bin($t);
		@now[4..7] = @bin[$i..$i+3];
		$write .= chr (oct ('0b' . join ('', @now[0..7]))) . chr (oct ('0b' . join ('', @now[8..15])));
	}
	for ($i=0; $i < 5; $i++) {
		my $t = '';
		sysread (OUT, $t, 2);
		my @now = str2bin($t);
		@now[4..7] = (0, 0, 0, 0);
		$write .= chr (oct ('0b' . join ('', @now[0..7]))) . chr (oct ('0b' . join ('', @now[8..15])));
	}
	sysseek (OUT, 44, 0);
	syswrite (OUT, $write);
	close OUT;
}

sub readWav ($) {
	open (READ, '<:raw', $_[0]);
	
	my $fsize = getFragSize($_[0]);
	$size = (stat($_[0]))[7];
	
	my @b_result = ();
	my $count = 0;
	my $text = '';
	
	sysseek (READ, 44, SEEK_SET);
	sysread (READ, $t, $size-44);
	for ($i = 0; $i <= $size-44; $i+=2) {
		my @here = str2bin(substr($t, $i, 1));
		if ($here[4] == 0 && $here[5]==0 && $here[6] == 0 && $here[7]==0) { $count++ }
		else {$count = 0};	
		last if $count > 4;
		@b_result = (@b_result, @here[4..7]);
	}
	for ($i = 0; $i <= $#b_result; $i+=8) {
		$text .= chr (oct ('0b' . join ('', @b_result[$i..$i+7])));
	}
	sysseek (READ, 0, SEEK_SET);
	close READ;
	
	return substr($text, 0, -2);
}

# sub readWav ($) {
	# open (READ, '<:raw', $_[0]);
	
	# my $fsize = getFragSize($_[0]);
	# $size = (stat($_[0]))[7];
	
	# my @b_result = ();
	# my $count = 0;
	# my $text = '';
	
	# sysseek (READ, 44, SEEK_SET);
	# for ($i = 44; $i <= $size; $i+=2) {
		# sysread (READ, $t, 2);
		# my @here = str2bin($t);
		# if ($here[4] == 0 && $here[5]==0 && $here[6] == 0 && $here[7]==0) { $count++ }
		# else {$count = 0};	
		# last if $count > 4;
		# @b_result = (@b_result, @here[4..7]);
	# }
	# for ($i = 0; $i <= $#b_result; $i+=8) {
		# $text .= chr (oct ('0b' . join ('', @b_result[$i..$i+7])));
	# }
	# sysseek (READ, 0, SEEK_SET);
	# close READ;
	
	# return substr($text, 0, -2);
# }