#!/usr/bin/perl

# chmod 755 
# sudo apt-get install libdevice-serialport-perl

my $inarg = $ARGV[0] ; 

use Device::MiniLED;
my $sign=Device::MiniLED->new(devicetype => "sign");


my $picFromBits=$sign->addPix(
    height => 16,
    width  => 96,
    data   =>  "$inarg"
);


if (length($inarg) > 200) {
    # a long string is probably in bits
	$sign->addMsg(
	  data => "$picFromBits",
	  effect => 'hold',
	);
} else {
	$sign->addMsg(
	  data => "$inarg",
	  effect => 'scroll',
	);
}


$sign->send(device => "/dev/ttyUSB0");