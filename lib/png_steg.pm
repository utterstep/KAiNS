sub byteLimitPng ($) {
	my $file = shift;
	my $img = Imager->new(file => $file);
	
	$file .= 'tmp'.rand(20).'.bmp';
	$img->write(file=>$file, type=>'bmp');

	my $limit = int(((stat($file))[7]-getOffsetBmp($file))/4)-7;
	
	unlink ($file);
	return $limit;
}

sub isContainerPng ($) { #should return boolean objects (IS_CONTAINER, IS_CRYPTED, IS_FILE_CONTAINER)
	my $file = shift;
	my $img = Imager->new(file => $file);
	
	$file .= 'tmp'.rand(20).'.bmp';
	$img->write(file=>$file, type=>'bmp');
	
	my @probe = isContainerBmp($file);
	
	unlink ($file);
	return @probe;
}

sub write2Png ($$) {
	my $text = $_[0];
	my $file = $_[1];
	my $imgIn = Imager->new(file => $file);
	
	$fileBmp = $file.'tmp'.rand(20).'.bmp';
	$imgIn->write(file=>$fileBmp, type=>'bmp');
	
	write2Bmp ($text, $fileBmp);
	
	my $imgOut = Imager->new(file => $fileBmp);
	$imgOut->write(file=>$file, type=>'png');
	unlink ($fileBmp);

	return 0;
}

sub readPng ($) {
	my $file = shift;
	my $img = Imager->new(file => $file);
	
	$file .= 'tmp'.rand(20).'.bmp';
	$img->write(file=>$file, type=>'bmp');
	
	my $text = readBmp($file);
	
	unlink ($file);
	return $text;
}

1;