#!/usr/bin/perl -w
#Модуль шифрования XOR-ом
use Digest::SHA qw(hmac_sha512256 sha512256);
use locale;
use utf8;

sub xcrypt ($$) {
	my ($key, $text) = @_;

	$key = hmac_sha512256(crypt($key, 'thu')) . sha512256(crypt($key, 'onu'));

	my $key_t = $key;
	my $k_l = length($key);
	my $length = length($text);
	$key_t = substr($key_t, 0, $length) if $k_l > $length;
	my $n = int($length/$k_l); #сколько раз необходимо повторить ключ целиком
	my $i = $length-($k_l*$n); #и сколько букв добавить потом
	$key_t = ($key_t x $n) . substr($key_t, 0, $i);
	my $crptd = $key_t ^ $text;
	return $crptd;
}

1;